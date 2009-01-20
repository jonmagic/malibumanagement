class AddAchSubmitted < ActiveRecord::Migration
  def self.up
    add_column :goto_transactions, :ach_submitted, :boolean, :default => false
  end
  
  def self.down
    remove_column :goto_transactions, :ach_submitted
  end
end
