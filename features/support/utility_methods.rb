module FeatureHelpers
  module UtilityMethods
    
    def find_han_alert_email(email_address, table=nil)
      step "delayed jobs are processed"
      ActionMailer::Base.deliveries.detect do |email|
        status = false
        if(!email.bcc.blank?)
          status ||= email.bcc.include?(email_address)
        end
        if(!email.to.blank?)
          status ||= email.to.include?(email_address)
        end

        unless table.nil?
          table.rows.each do |row|
            field, value = row.first, row.last

            case field
            when /subject/
              status &&= email.subject =~ /#{Regexp.escape(value)}/
            when /body contains$/
              status &&= email.body =~ /#{Regexp.escape(value)}/
            when /body does not contain$/
              status &&= !(email.body =~ /#{Regexp.escape(value)}/)
            when /body contains alert acknowledgment link/
              attempt = User.find_by_email(email_address).alert_attempts.last
              if value.blank?
                status &&= email.body.include?(email_acknowledge_alert_url(attempt.alert, :call_down_response => 1, :host => HOST))
              else
                call_down_response = attempt.alert.becomes(HanAlert).reload.call_down_messages.index(value).to_i
                status &&= email.body.include?(email_acknowledge_alert_url(attempt.alert, :call_down_response => call_down_response, :host => HOST))
              end
            when /body does not contain alert acknowledgment link/
              attempt = User.find_by_email(email_address).alert_attempts.last
              status &&= !email.body.include?(email_acknowledge_alert_url(attempt, :host => HOST, :call_down_response => 1))
            when /attachments/
              filenames = email.attachments
              status &&= !filenames.nil? && value.split(',').all?{|m| filenames.map(&:original_filename).include?(m) }
            else
              raise "The field #{field} is not supported, please update this step if you intended to use it."
            end
          end
        end
        status
      end
    end

    def find_han_alert_email_via_SWN(email_address, table=nil)
      step "delayed jobs are processed"
      Service::Swn::Message.deliveries.detect do |email|
        xml = Nokogiri::XML(email.body)
        status = false
        status ||= (xml.search('//swn:rcpts/swn:rcpt/swn:contactPnts/swn:contactPntInfo[@type="Email"]/swn:address',
                {"swn" => "http://www.sendwordnow.com/notification"})).map(&:inner_text).include?(email_address)
        unless table.nil?
          table.rows.each do |row|
            field, value = row.first, row.last

            case field
            when /subject/
              status &&= (xml.search('//swn:SendNotificationInfo/swn:notification/swn:subject',
                {"swn" => "http://www.sendwordnow.com/notification"})).map(&:inner_text).first =~ /#{Regexp.escape(value)}/
            when /body contains$/
              status &&= email.body =~ /#{Regexp.escape(value)}/
            when /body does not contain$/
              status &&= !(email.body =~ /#{Regexp.escape(value)}/)
            when /body contains alert acknowledgment link/
              attempt = User.find_by_email(email_address).alert_attempts.last
              if value.blank?
                status &&= (xml.search('//swn:SendNotificationInfo/swn:gwbText',
                  {"swn" => "http://www.sendwordnow.com/notification"})).map(&:inner_text).first =~ /#{Regexp.escape("Please press one to acknowledge this alert.")}/
              else
                call_down_response = attempt.alert.becomes(HanAlert).reload.call_down_messages.index(value).to_i
                status &&= (xml.search('//swn:SendNotificationInfo/swn:gwbText',
                  {"swn" => "http://www.sendwordnow.com/notification"})).map(&:inner_text)[call_down_response-1] =~ /#{Regexp.escape(value)}/
              end
            when /body does not contain alert acknowledgment link/
              attempt = User.find_by_email(email_address).alert_attempts.last
              if value.blank?
                status &&= (xml.search('//swn:SendNotificationInfo/swn:gwbText',
                  {"swn" => "http://www.sendwordnow.com/notification"})).empty?
              else
                call_down_response = attempt.alert.becomes(HanAlert).reload.call_down_messages.index(value).to_i
                status &&= !(xml.search('//swn:SendNotificationInfo/swn:gwbText',
                  {"swn" => "http://www.sendwordnow.com/notification"})).map(&:inner_text)[call_down_response-1] =~ /#{Regexp.escape(value)}/
              end
            when /attachments/
              filenames = email.attachments
              status &&= !filenames.nil? && value.split(',').all?{|m| filenames.map(&:original_filename).include?(m) }
            else
              raise "The field #{field} is not supported, please update this step if you intended to use it."
            end
          end
        end
        status
      end
    end
    
    def create_han_alert_with(attributes)
      attributes['from_jurisdiction'] = Jurisdiction.find_by_name(attributes['from_jurisdiction']) unless attributes['from_jurisdiction'].blank?
      jurisdictions = (attributes.delete('jurisdictions') || attributes.delete('jurisdiction')).to_s.split(',').map{|m| Jurisdiction.find_by_name(m.strip)}
      roles = attributes.delete('roles').to_s.split(',').map{
        |m| Role.find_or_create_by_name(m.strip)
      }
      users = attributes.delete('people').to_s.split(',').map{ |m|
        first_name, last_name = m.split(/\s+/)
        User.find_by_first_name_and_last_name(first_name, last_name)
      }
      users += attributes.delete('emails').to_s.split(',').map{ |m|
        User.find_by_email(m.strip)
      }
      gps = []
      if attributes.has_key?('groups')
        attributes.delete('groups').each do |g|
           gps << ( Audience.find( Group.find_by_name(g).id ) )
        end
        attributes['audiences'] += gps
      end
      
      if attributes['author'].blank?
        attributes['author_id'] = current_user.id unless current_user.nil?
      else
        attributes['author_id'] = User.find_by_display_name(attributes.delete('author')).id
      end

      if attributes.has_key?('acknowledge')
        attributes['acknowledge'] = true_or_false(attributes.delete('acknowledge'))
        attributes['call_down_messages'] = {}
        attributes['call_down_messages']['1'] = "Please press one to acknowledge this alert."
      end

      if attributes.has_key?('not_cross_jurisdictional')
        attributes['not_cross_jurisdictional'] = true_or_false(attributes.delete('not_cross_jurisdictional'))
      end

      if attributes.has_key?("communication methods")
        attributes['device_types']= attributes.delete('communication methods').split(",").map{|device_name| "Device::#{device_name.strip}Device"}
      end

      if attributes.has_key?("delivery time")
        delivery_time=attributes.delete("delivery time")
        case delivery_time
          when /73 hours?/i
            attributes['delivery_time']=4420
          when /72 hours?/i
            attributes['delivery_time']=4320
          when /24 hours?/i
            attributes['delivery_time']=1440
          when /1 hours?/i
            attributes['delivery_time']=60
          when /60 minutes?/i
            attributes['delivery_time']=60
          when /15 minutes?/i
            attributes['delivery_time']=15
          else
            raise "You picked an invalid delivery time"
        end
      else
        attributes['delivery_time'] = 60
      end
      
      

      attributes["call_down_messages"] = {} if attributes["call_down_messages"].nil?
      attributes.each do |key, value|
        if key =~ /alert_response_/
          response = key.split("_").last
          attributes["call_down_messages"][response] = value
          attributes.delete(key)
        end
      end

      audience = Audience.new(:jurisdictions => jurisdictions, :roles => roles, :users => users, :groups => gps)
      attributes["audiences"] = [audience]
      alert = FactoryGirl.create(:han_alert, attributes)
    end
  end
end

World(FeatureHelpers::UtilityMethods)