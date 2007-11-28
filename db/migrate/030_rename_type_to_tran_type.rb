class RenameTypeToTranType < ActiveRecord::Migration
  def self.up
    rename_column :goto_transactions, :type, :tran_type
  end
  def self.down
  end
end