class LengthenBatchSubmitted < ActiveRecord::Migration
  def self.up
    change_column :eft_batches, :submitted, :text, :default => "--- {}\n\n"
  end
  
  def self.down
    # change_column :eft_batches, :submitted, :string, :default => "--- {}\n\n"
  end
end
