class Han::HanAlertObserver < ActiveRecord::Observer
  observe HanAlert

  def after_initialize(alert)
    alert.acknowledge = true if alert.acknowledge.nil?
  end

  def before_create(alert)
    alert.send(:write_attribute,"sent_at", Time.zone.now) if alert.sent_at.blank?
    alert.message_type = alert.class::MessageTypes[:alert] if alert.message_type.blank?
    if alert.acknowledge && alert.call_down_messages.blank?
      alert.call_down_messages = {}
      alert.call_down_messages["1"] = "Please press one to acknowledge this alert."
    end
  end

  def before_save(alert)
    # for cascade alerting
  if !Jurisdiction.find_by_name(alert.sender).nil?
      jurs = Jurisdiction.foreign.find(:all, :conditions => ['id in (?)', alert.audiences.map(&:jurisdiction_ids).flatten.uniq])
      level=[]
      level << "Federal" if jurs.detect{|j| j.root?}
      level << "State" if jurs.detect{|j| !j.root? && !j.leaf?}
      level << "Local" if jurs.detect{|j| j.leaf?}
      alert.send(:write_attribute,"jurisdiction_level",  level.join(","))
    end
  end

  def after_create(alert)
    if alert.identifier.nil?
      alert.send(:write_attribute,:identifier, "#{Agency[:agency_abbreviation]}-#{Time.zone.now.strftime("%Y")}-#{alert.id}")
    end
    if alert.distribution_id.nil? || (!alert.original_alert.nil? && alert.distribution_id == alert.original_alert.distribution_id)
      alert.send(:write_attribute,:distribution_id, "#{Agency[:agency_abbreviation]}-#{alert.created_at.strftime("%Y")}-#{alert.id}")
    end
    if alert.sender_id.nil?
      alert.send(:write_attribute,:sender_id, "#{Agency[:agency_identifier]}@#{Agency[:agency_domain]}")
    end
    if !alert.original_alert.nil? && alert.distribution_reference.nil?
      alert.send(:write_attribute,:distribution_reference, "#{alert.original_alert.distribution_id},#{alert.sender_id},#{alert.original_alert.sent_at.utc.iso8601(3)}")
    end
    if !alert.original_alert.nil? && alert.reference.nil?
      alert.send(:write_attribute,:reference, "#{Agency[:agency_identifier]},#{alert.original_alert.distribution_id},#{alert.original_alert.sent_at.utc.iso8601(3)}")
    end
    alert.save!
  end
end
