require File.join(Rails.root,"config","initializers","system")
require File.join(Rails.root,"vendor","plugins","han","app","models","edxl","message")

class PhinmsPickupWorker < BackgrounDRb::MetaWorker
  set_worker_name :phinms_pickup_worker

  def create(args = nil)
  end

  def check(args = nil)
    alerts = CDCFileExchange.new.receive_all_incoming_alerts
    alerts.each do |alert|
      next unless alert[:payload_file] && alert[:payload_file][:binary]
      xml = Base64.decode64(alert[:payload_file][:binary])
      begin
        if Edxl::MessageContainer.parse(xml).distribution_type == 'Ack'
          PHINMS_RECEIVE_LOGGER.debug "Parsing acknowledgement"
          ack=Edxl::AckMessage.parse(xml)
          PHINMS_RECEIVE_LOGGER.debug "Acknowledgement parsed: #{alert[:name]}"
        else
          PHINMS_RECEIVE_LOGGER.debug "Parsing cascade message #{alert[:name]}"
          msg=Edxl::Message.parse(xml, {:sender => alert[:sender]})
          PHINMS_RECEIVE_LOGGER.debug "Cascade Message Parsed: #{msg.distribution_id}"
        end
      rescue
        next
      end
    end
    true
    # if File.exist?(PHINMS_INCOMING)
      # phindir=Dir.new PHINMS_INCOMING
      # phindir.each do |file|
        # unless file == "." || file == ".."
          # filename = File.join(PHINMS_INCOMING, file)
          # archive_filename = File.join(PHINMS_ARCHIVE, file)
          # error_filename = File.join(PHINMS_ERROR, file)
          # xml=""
          # begin
            # unless filename.first == "."
              # xml= File.read(filename)
              # if Edxl::MessageContainer.parse(xml).distribution_type == 'Ack'
                # PHINMS_RECEIVE_LOGGER.debug "Parsing acknowledgement"
                # ack=Edxl::AckMessage.parse(xml)
                # PHINMS_RECEIVE_LOGGER.debug "Acknowledgement parsed: #{filename}"
              # else
                # PHINMS_RECEIVE_LOGGER.debug "Parsing cascade message #{xml}"
                # msg=Edxl::Message.parse(xml)
                # PHINMS_RECEIVE_LOGGER.debug "Cascade Message Parsed: #{msg.distribution_id}"
              # end
              # File.mv( filename, archive_filename)
            # end
          # rescue Exception => e
            # PHINMS_RECEIVE_LOGGER.error "Error parsing PHIN-MS message:\n#{e}\n#{xml}"
            # File.mv( filename, error_filename)
            # AppMailer.deliver_system_error(e, "Filename: #{filename}\nContents:\n#{xml}")
          # end
        # end
      # end
    # end
  end
end