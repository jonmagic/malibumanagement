class LengthenBatchSubmitted < ActiveRecord::Migration
  def self.up
    change_column :eft_batches, :submitted, :text
  end
  
  def self.down
    # change_column :eft_batches, :submitted, :string, :default => "--- {}\n\n"
  end
end
