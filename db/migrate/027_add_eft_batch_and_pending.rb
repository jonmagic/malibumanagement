class AddEftBatchAndPending < ActiveRecord::Migration
  def self.up
    create_table :eft_batches do |t|
      t.column :for_month, :string # month #1-12 == "Time#year(2007)/Time#month(10)"
      t.column :submitted_at, :datetime
      t.column :submitted_by, :integer
      t.column :no_eft_count, :integer
      t.column :invalid_count, :integer
    end
  end
  def self.down
    drop_table :eft_batches
  end
end