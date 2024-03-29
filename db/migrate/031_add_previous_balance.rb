class AddPreviousBalance < ActiveRecord::Migration
  def self.up
    add_column :goto_transactions, :previous_balance, :float
    add_column :goto_transactions, :previous_payment_amount, :float
  end
  def self.down
    remove_column :goto_transactions, :previous_balance
    remove_column :goto_transactions, :previous_payment_amount
  end
end
