class CreateHanAlert < ActiveRecord::Migration
  def self.up
    create_table :han_alerts, :id => false do |t|
      t.string :severity
      t.string :status
      t.boolean :sensitive
      t.integer :delivery_time
      t.integer :alert_id
      t.datetime :sent_at
      t.integer :from_organization_id
      t.string :from_organization_name
      t.string :from_organization_oid
      t.string :identifier
      t.string :scope
      t.string :category
      t.string :program
      t.string :urgency
      t.string :certainty
      t.string :jurisdiction_level
      t.string :alert_references
      t.integer :from_jurisdiction_id
      t.integer :original_alert_id
      t.string :short_message
      t.string :message_recording_file_name
      t.string :message_recording_content_type
      t.string :message_recording_file_size
      t.string :distribution_reference
      t.string :caller_id
      t.string :ack_distribution_reference
      t.string :distribution_id
      t.string :reference
      t.string :sender_id
      t.text :call_down_messages
      t.boolean :not_cross_jurisdictional, :default => false
      t.index :alert_id
    end

    if Alert.column_names.include?('references')
      rename_column(:alerts, :references, :alert_references)
      add_column(:alert_attempts, :alert_type, :string)
      add_column(:alert_ack_logs, :alert_type, :string)
      add_column(:alert_device_types, :alert_type, :string)
    end


    ::Alert.find_in_batches(:select => "id") do |alerts|
      alerts.each do |alert|
        execute("INSERT INTO han_alerts SELECT severity, status, sensitive, delivery_time, id, sent_at, from_organization_id, from_organization_name, from_organization_oid, \
          identifier, scope, category, program, urgency, certainty, jurisdiction_level, alert_references, from_jurisdiction_id, original_alert_id, short_message, \
          message_recording_file_name, message_recording_content_type, message_recording_file_size, distribution_reference, caller_id, ack_distribution_reference, \
          distribution_id, reference, sender_id, call_down_messages, not_cross_jurisdictional FROM alerts WHERE alerts.id=#{alert.id}")
      end
    end

    remove_column(:alerts, :severity)
    remove_column(:alerts, :status)
    remove_column(:alerts, :sensitive)
    remove_column(:alerts, :delivery_time)
    remove_column(:alerts, :sent_at)
    remove_column(:alerts, :from_organization_id)
    remove_column(:alerts, :from_organization_name)
    remove_column(:alerts, :from_organization_oid)
    remove_column(:alerts, :identifier)
    remove_column(:alerts, :scope)
    remove_column(:alerts, :category)
    remove_column(:alerts, :program)
    remove_column(:alerts, :urgency)
    remove_column(:alerts, :certainty)
    remove_column(:alerts, :jurisdiction_level)
    remove_column(:alerts, :alert_references)
    remove_column(:alerts, :from_jurisdiction_id)
    remove_column(:alerts, :original_alert_id)
    remove_column(:alerts, :short_message)
    remove_column(:alerts, :message_recording_file_name)
    remove_column(:alerts, :message_recording_content_type)
    remove_column(:alerts, :message_recording_file_size)
    remove_column(:alerts, :distribution_reference)
    remove_column(:alerts, :caller_id)
    remove_column(:alerts, :ack_distribution_reference)
    remove_column(:alerts, :distribution_id)
    remove_column(:alerts, :reference)
    remove_column(:alerts, :sender_id)
    remove_column(:alerts, :call_down_messages)
    remove_column(:alerts, :not_cross_jurisdictional)

    CreateMTIFor(HanAlert)
    execute("UPDATE alerts SET alert_type = 'HanAlert' WHEN alert_type IS NULL")
  end

  def self.down
    add_column(:alerts, :severity, :string)
    add_column(:alerts, :status, :string)
    add_column(:alerts, :sensitive, :boolean)
    add_column(:alerts, :delivery_time, :integer)
    add_column(:alerts, :sent_at, :datetime)
    add_column(:alerts, :from_organization_id, :integer)
    add_column(:alerts, :from_organization_name, :string)
    add_column(:alerts, :from_organization_oid, :string)
    add_column(:alerts, :identifier, :string)
    add_column(:alerts, :scope, :string)
    add_column(:alerts, :category, :string)
    add_column(:alerts, :program, :string)
    add_column(:alerts, :urgency, :string)
    add_column(:alerts, :certainty, :string)
    add_column(:alerts, :jurisdiction_level, :string)
    add_column(:alerts, :alert_references, :string)
    add_column(:alerts, :from_jurisdiction_id, :integer)
    add_column(:alerts, :original_alert_id, :integer)
    add_column(:alerts, :short_message, :string)
    add_column(:alerts, :message_recording_file_name, :string)
    add_column(:alerts, :message_recording_content_type, :string)
    add_column(:alerts, :message_recording_file_size, :string)
    add_column(:alerts, :distribution_reference, :string)
    add_column(:alerts, :caller_id, :string)
    add_column(:alerts, :ack_distribution_reference, :string)
    add_column(:alerts, :distribution_id, :string)
    add_column(:alerts, :reference, :string)
    add_column(:alerts, :sender_id, :string)
    add_column(:alerts, :call_down_messages, :text)
    add_column(:alerts, :not_cross_jurisdictional, :boolean, :default => false)

    ::Alert.find_in_batches(:select => "id", :conditions => ["alert_type = 'HanAlert'"]) do |alerts|
      alerts.each do |alert|
        execute("UPDATE alerts SET severity = han_alerts.severity, status = han_alerts.status, sensitive = han_alerts.sensitive, delivery_time = han_alerts.delivery_time, \
          sent_at = han_alerts.sent_at, from_organization_id = han_alerts.from_organization_id, from_organization_name = han_alerts.from_organization_name, \
          from_organization_oid = han_alerts.from_organization_oid, identifier = han_alerts.identifier, scope = han_alerts.scope, category = han_alerts.category, \
          program = han_alerts.program, urgency = han_alerts.urgency, certainty = han_alerts.certainty, jurisdiction_level = han_alerts.jurisdiction_level, \
          alert_references = han_alerts.alert_references, from_jurisdiction_id = han_alerts.from_jurisdiction_id, original_alert_id = han_alerts.original_alert_id, \
          short_message = han_alerts.short_message, message_recording_file_name = han_alerts.message_recording_file_name, message_recording_content_type = han_alerts.message_recording_content_type, \
          message_recording_file_size = han_alerts.message_recording_file_size, distribution_reference = han_alerts.distribution_reference, caller_id = han_alerts.caller_id, \
          ack_distribution_reference = han_alerts.ack_distribution_reference, distribution_id = han_alerts.distribution_id, reference = han_alerts.reference, sender_id = han_alerts.sender_id, \
          call_down_messages = han_alerts.call_down_messages, not_cross_jurisdictional = han_alerts.not_cross_jurisdictional FROM (SELECT * FROM han_alerts WHERE alert_id=#{alert.id}) AS han_alerts WHERE id=#{alert.id}")
      end
    end

    DropMTIFor(HanAlert)
    drop_table :han_alerts

    rename_column(:alerts, :alert_references, :references)
    remove_column(:alert_attempts, :alert_type)
    remove_column(:alert_ack_logs, :alert_type)
    remove_column(:alert_device_types, :alert_type)
  end
end
