class RemoveCustomers < ActiveRecord::Migration
  def self.up
    drop_table :customers
  end

  def self.down
    create_table :customers do |t|
    end
  end
end
