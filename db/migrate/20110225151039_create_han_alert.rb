class CreateHanAlert < ActiveRecord::Migration
  def self.up
    create_table :han_alerts, :id => false do |t|
      t.string :severity
      t.string :status
      t.boolean :sensitive
      t.integer :delivery_time
      t.integer :alert_id
      t.datetime :sent_at
      t.index :alert_id
    end

    add_column(:alerts, :type, :string)
    rename_column(:alerts, :references, :alert_references)

    ::Alert.find_in_batches(:select => "id") do |alert|
      execute("INSERT INTO han_alerts (alert_id, severity, status, sensitive, delivery_time, sent_at) VALUES(SELECT(id, severity, status, sensitive, delivery_time, sent_at) FROM alerts WHERE id=#{alert.id})")
    end

    remove_column(:alerts, :severity)
    remove_column(:alerts, :status)
    remove_column(:alerts, :sensitive)
    remove_column(:alerts, :delivery_time)
    remove_column(:alerts, :sent_at)

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

    remove_column(:alerts, :type)
    rename_column(:alerts, :alert_references, :references)
  end
end
