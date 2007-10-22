class AddEftBatchReadyField < ActiveRecord::Migration
  def self.up
    add_column :eft_batches, :eft_ready, :boolean
  end

  def self.down
    remove_column :eft_batches, :eft_ready
  end
end
