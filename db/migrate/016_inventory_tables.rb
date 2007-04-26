class InventoryTables < ActiveRecord::Migration
  def self.up
    create_table :inventory_reports do |t|
      t.column :signer_id,    :integer
      t.column :signer_hash,  :string
      t.column :signer_date,  :datetime
    end
    execute 'INSERT INTO form_types(friendly_name, name, can_have_notes, can_have_multiple_drafts, draftable, reeditable) VALUES("Inventory Report", "InventoryReport", 1, 0, 1, 0)'
  end

  def self.down
    drop_table :inventory_reports
    execute 'DELETE FROM form_types WHERE name="InventoryReport"'
    execute 'DELETE FROM form_instances WHERE data_type="InventoryReport"'
  end
end
