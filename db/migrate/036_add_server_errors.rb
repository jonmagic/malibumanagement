class AddServerErrors < ActiveRecord::Migration
  def self.up
    add_column :goto_transactions, :server_error, :string
  end
  
  def self.down
    remove_column :goto_transactions, :server_error
  end
end
