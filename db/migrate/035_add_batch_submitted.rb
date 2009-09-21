class AddBatchSubmitted < ActiveRecord::Migration
  def self.up
    # To change from an already-created string column, run:
    # ALTER TABLE eft_batches MODIFY submitted TEXT;
    add_column :eft_batches, :submitted, :text
  end
  
  def self.down
    remove_column :eft_batches, :submitted
  end
end
