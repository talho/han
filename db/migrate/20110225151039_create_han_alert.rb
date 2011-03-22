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

    rename_column(:alerts, :references, :alert_references)
    add_column(:alert_attempts, :alert_type, :string)
    add_column(:alert_ack_logs, :alert_type, :string)
    add_column(:alert_device_types, :alert_type, :string)

    ::Alert.find_in_batches(:select => "id") do |alert|
      execute("INSERT INTO han_alerts (alert_id, severity, status, sensitive, delivery_time, sent_at) VALUES(SELECT(id, severity, status, sensitive, delivery_time, sent_at) FROM alerts WHERE id=#{alert.id})")
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
  end

  def self.down
    DropMTIFor(HanAlert)

    add_column(:alerts, :severity, :string)
    add_column(:alerts, :status, :string)
    add_column(:alerts, :sensitive, :boolean)
    add_column(:alerts, :delivery_time, :integer)
    add_column(:alerts, :sent_at, :datetime)

    ::Alert.find_in_batches(:select => "id") do |alert|
      execute("UPDATE alerts SET (severity, status, sensitive, delivery_time, sent_at) VALUES(SELECT(severity, status, sensitive, delivery_time, sent_at) FROM han_alerts WHERE alert_id=#{alert.id})")
    end

    drop_table :han_alerts

    remove_column(:alerts, :alert_type)
    rename_column(:alerts, :alert_references, :references)
    remove_column(:alert_attempts, :alert_type)
    remove_column(:alert_ack_logs, :alert_type)
    remove_column(:alert_device_types, :alert_type)
  end
end
