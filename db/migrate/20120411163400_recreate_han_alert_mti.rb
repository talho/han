class RecreateHanAlertMti < ActiveRecord::Migration
  def self.up
    DropMTIFor(HanAlert)
    CreateMTIFor(HanAlert)    
  end

  def self.down    
  end
end
