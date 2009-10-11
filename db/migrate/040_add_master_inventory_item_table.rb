class AddMasterInventoryItemTable < ActiveRecord::Migration
  def self.up
    create_table :master_inventory_items do |t|
      t.column :master_inventory_report_id, :integer
      t.column :store_name, :string
      t.column :inventory_code, :string
      t.column :quantity, :integer
    end
  end

  def self.down
    drop_table :master_inventory_items
  end
end
