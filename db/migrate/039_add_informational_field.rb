class AddInformationalField < ActiveRecord::Migration
  def self.up
    add_column :goto_transactions, :information, :string
  end
  
  def self.down
    remove_column :goto_transactions, :information
  end
end
