require 'dispatcher'

module HAN
  module Organization
    def self.included(base)
      base.send :extend, ClassMethods
    end

    module ClassMethods
    end

    def deliver(alert)
      raise 'not foreign' unless foreign?
      #File.open(File.join(phin_ms_queue, "#{cascade_alert.distribution_id}.edxl"), 'w') {|f| f.write cascade_alert.to_edxl }
      begin
        CDCFileExchange.new.send_alert(alert)
      rescue
        # swallow exception for now. the file exchange logs
      end
    end
  end

  Dispatcher.to_prepare do
    ::Organization.send(:include, HAN::Organization)
  end
end