class RemoveCustomers < ActiveRecord::Migration
  def self.up
    drop_table :customers
  end

  def self.down
    create_table :customers do |t|
      t.column :created_at,     :datetime
    end
  end
end
