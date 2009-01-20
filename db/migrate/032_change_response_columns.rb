class ChangeResponseColumns < ActiveRecord::Migration
  def self.up
    rename_column :goto_transactions, :tran_time, :transacted_at
    remove_column :goto_transactions, :tran_date
    remove_column :goto_transactions, :recorded
    remove_column :goto_transactions, :term_code
    remove_column :goto_transactions, :auth_code
  end
  def self.down
    add_column :goto_transactions, :auth_code, :string
    add_column :goto_transactions, :term_code, :string
    add_column :goto_transactions, :recorded, :boolean
    add_column :goto_transactions, :tran_date, :date
    rename_column :goto_transactions, :transacted_at, :tran_time
  end
end
