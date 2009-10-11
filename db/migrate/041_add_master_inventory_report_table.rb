class AddMasterInventoryReportTable < ActiveRecord::Migration
  def self.up
    create_table :master_inventory_reports do |t|
      t.column :created_at,  :datetime
      t.column :needs_inventory_pulled, :string
    end
  end

  def self.down
    drop_table :master_inventory_reports
  end
end
