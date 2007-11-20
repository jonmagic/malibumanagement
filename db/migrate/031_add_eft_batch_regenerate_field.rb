class AddEftBatchRegenerateField < ActiveRecord::Migration
  def self.up
    add_column :eft_batches, :regenerate_now, :string
  end

  def self.down
    remove_column :eft_batches, :regenerate_now
  end
end
