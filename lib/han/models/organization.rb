
module Han
  module Models
    module Organization
      def self.included(base)
        base.send :extend, ClassMethods
      end
  
      module ClassMethods
        def deliver(alert)
          raise 'not foreign' if alert.alert_attempts.map{|aa| aa.organization}.compact.index{|o| o.foreign?}.nil?
          #File.open(File.join(phin_ms_queue, "#{cascade_alert.distribution_id}.edxl"), 'w') {|f| f.write cascade_alert.to_edxl }
          begin
            CDCFileExchange.new.send_alert(alert)
          rescue
            # swallow exception for now. the file exchange logs
          end
        end
      end
    end
  end
end