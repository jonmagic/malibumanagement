class AddPreviousBalance < ActiveRecord::Migration
  def self.up
    add_column :goto_transactions, :recd_date_due, :boolean, :default => false
  end
  def self.down
    remove_column :goto_transactions, :recd_date_due
  end
end
