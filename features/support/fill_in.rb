module FeatureHelpers
  module FillInMethods
    def fill_in_han_alert_form(table = nil)
      fields = {
        #"Title" => "H1N1 SNS push packs to be delivered tomorrow",
        "Message" => "For more details, keep on reading...",
        "Severity" =>"Moderate",
        #"Status" => "Actual",
        "Acknowledge"  => "Normal",
        #"Communication methods" => "E-mail",
        "Delivery Time" => "15 minutes"
      }

      if table.is_a?(Hash)
        fields.merge!(table)
      elsif !table.nil?
        fields.merge!(table.rows_hash)
      end

      details = Hash[fields.select {|key, value| ["Title","Message","Short Message","Communication methods","Communication method","Jurisdiction",
                                             "Status","Severity","Delivery Time","Acknowledge","Sensitive","Alert Response 1",
                                             "Alert Response 2","Alert Response 3","Alert Response 4","Alert Response 5","Caller ID"].include?(key)}]
      audience = Hash[fields.select {|key, value| ["Jurisdictions","Roles","Role","Organizations","Organization","Groups","Group","People"].include?(key)}]

      ["Alert Response 1","Alert Response 2","Alert Response 3","Alert Response 4","Alert Response 5"].each do |resp|
        raise "Cannot fill in Alert Responses without Advanced acknowledgment" if details.has_key?(resp) && details["Acknowledge"] != "Advanced"
        fill_in_han_alert_field("Acknowledge",details["Acknowledge"])
      end
      unless details["Caller ID"].blank?
        if details["Communication methods"] =~ /Phone/
          fill_in_han_alert_field("Communication methods" , "Phone")
        elsif details["Communication methods"] =~ /SMS/
          fill_in_han_alert_field("Communication methods" , "SMS")
        end
      end
      details.each do |label, value|
        fill_in_han_alert_field(label, value)
      end
      if audience.size > 0
        When "I press \"Select an Audience\""
        audience.each do |label, value|
          fill_in_han_alert_field(label, value)
        end
      end
    end

    def fill_in_han_alert_field(label, value)
      case label
      when "People"
        value.split(',').each { |name| fill_in_fcbk_control(name) }
      when /Jurisdictions/, /Role[s]?/, /Organization[s]?/, /^Groups?$/, /^Communication methods?/
        value.split(',').map(&:strip).each{ |r| check r }
        when 'Acknowledge', 'Status', 'Severity', 'Jurisdiction','Event Interval'
          select value, :from => label
        when 'Delivery Time'
          case value
            when /^(\d+) hours$/ then
              if HanAlert::DeliveryTimes.include?($1.to_i.hours.to_i/1.minute.to_i)
                select value, :from => "han_alert_delivery_time"
              else
                raise "Not a valid Delivery Time"
            end
            when /^(\d+) minutes$/ then
              if HanAlert::DeliveryTimes.include? $1.to_i
                select value, :from => "han_alert_delivery_time"
              else
                raise "Not a valid Delivery Time"
            end
            else
              raise "Not a valid Delivery Time"
          end
        when 'Acknowledge', 'Sensitive'
          id = "han_alert_#{label.parameterize('_')}"
          if value == '<unchecked>'
            uncheck id
          else
            check id
          end
      when 'Communication methods'
        value.split(',').each { |name| check value }
      when 'Caller ID'
        fill_in label, :with => value

      when "Message Recording"
        attach_file(:alert_message_recording, File.join(Rails.root.to_s, 'features', 'fixtures', value), "audio/x-wav")
      when "Short Message"
        fill_in "han_alert_short_message", :with => value
      when "Title"
        fill_in label, :with => value
      when "Message"
        # instantly set the message text to avoid javascript not responding
        # dialog notice in firefox
        page.execute_script("$('#han_alert_message').val('#{value}')")
      when "Alert Response 1", "Alert Response 2", "Alert Response 3", "Alert Response 4", "Alert Response 5"
        fill_in label, :with => value
      else
        raise "Unexpected: #{label} with value #{value}. You may need to update this step."
      end
    end
  end
end