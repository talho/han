class RecipeInternal::HanAlertLogRecipe < Recipe

  class << self

    def description  # recipe description
      "Report of all han alerts that are within your jurisdictions"
    end

    def helpers
      []
    end

    def template_path
      File.join(Rails.root, 'vendor','plugins','han','app','views', 'reports','han_alert', 'han_alert_log.html.erb')
    end

    def layout_path
      File.join(Rails.root, 'app','views','reports','layouts','report.html.erb')
    end

#      ['Name', 'Email', 'Acknowledged by', 'Alert Response', 'Alert Response Message' ]
    def template_directives
      [['display_name','Name'],['email','Email Address'],['device_type','Acknowledgement Device'],
       ['response','Acknowledgement Response'],['time','Acknowledgement Time']]
    end

    def current_user
      @current_user
    end

    def capture_to_db(report)
      @current_user = report.author
      dataset = report.dataset
      if report.criteria.present?
        criteria = report.criteria
        begin
          # i.e. Invitation.find(params)
          result = criteria[:model].constantize.send(criteria[:method],criteria[:params])
          dataset.insert({:report=>result.as_report(:inject=>{:created_at=>Time.now.utc}),:report_id=>report.id})
          dataset.insert( {:meta=>{:template_directives=>template_directives},:report_id=>report.id} )
          index = 0
          result.alert_attempts.each do |attempt|
            begin
              doc = {:i => index += 1}
              doc[:report_id] = report.id
              doc[:display_name]= attempt.user.display_name
              doc[:email] = attempt.user.email
              doc[:device_type] = attempt.acknowledged_alert_device_type.device.constantize.display_name
              doc[:response] = attempt.call_down_response > 0 ? result.call_down_messages[attempt.call_down_response.to_s] : "Acknowledged"
              doc[:time] = attempt.acknowledged_at.utc
              dataset.insert(doc)
            rescue NoMethodError => error
              # skip this illegitimate attempt
            end
          end
          dataset.create_index("i")
        rescue StandardError => error
          raise error
        end
      end
    end

    def generate_rendering( report, view, template, filters=nil )
      filtered_at = nil
      pre_where = {"i"=>{'$exists'=>true},:report_id=>report.id}
      if filters.present?
        filtered_at = filters["filtered_at"]
        fa = filtered_at.nil? ? "" : "-#{filtered_at}"
        filename = "#{report.name}#{fa}.html"
        where_filter = filters_for_query(filters["elements"])
        where = pre_where.merge(where_filter)
      else
        filename = "#{report.name}.html"
        where = pre_where
      end
      subject = report.dataset.find({:report=>{:$exists=>true},:report_id=>report.id}).first['report']
      results = []
      report.dataset.find(where).each{|e| results << e}
      Dir.mktmpdir do |dir|
        path = File.join dir, filename
        File.open(path, 'wb') do |f|
          rendering = view.render(:inline=>template,:type=>'html',
                                  :locals=>{:report=>subject,
                                            :attempts=>results,
                                            :filters=>filters},
                                  :layout=>layout_path)
          f.write(rendering)
        end
        report.update_attributes( :rendering=>File.new(path, "rb"), :incomplete=>false )
      end
    end

  end

end

