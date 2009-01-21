class AddCheckNumber < ActiveRecord::Migration
  def self.up
    add_column :goto_transactions, :check_number, :string
  end
  
  def self.down
    remove_column :goto_transactions, :check_number
  end
end
