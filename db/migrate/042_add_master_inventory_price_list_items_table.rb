class AddMasterInventoryPriceListItemsTable < ActiveRecord::Migration
  def self.up
    create_table :master_inventory_price_list_items do |t|
      t.column :inventory_code, :string
      t.column :description, :string
      t.column :cost_price, :decimal, :precision => 8, :scale => 2
      t.column :retail_price, :decimal, :precision => 8, :scale => 2
      t.column :created_at,  :datetime
    end
  end

  def self.down
    drop_table :master_inventory_price_list_items
  end
end
