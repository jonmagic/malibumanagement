class AddBatchLocked < ActiveRecord::Migration
  def self.up
    add_column :eft_batches, :locked, :boolean, :default => false
  end
  def self.down
    remove_column :eft_batches, :locked
  end
end
