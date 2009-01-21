class AddLineItems < ActiveRecord::Migration
  def self.up
    create_table :inventory_line_items do |t|
      t.column :inventory_report_id,  :integer
      t.column :name,       :string
      t.column :label,      :string
      t.column :should_be,  :integer
      t.column :actual,     :integer
    end
  end

  def self.down
    drop_table :inventory_line_items
  end
end
