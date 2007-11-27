class AddLastRegenerate < ActiveRecord::Migration
  def self.up
    add_column :eft_batches, :last_total_regenerate, :datetime
  end
  def self.down
  end
end