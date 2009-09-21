class AddBatchSubmitted < ActiveRecord::Migration
  def self.up
    add_column :eft_batches, :submitted, :text
  end
  
  def self.down
    remove_column :eft_batches, :submitted
  end
end
