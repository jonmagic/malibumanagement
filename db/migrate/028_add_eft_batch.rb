class AddEftBatch < ActiveRecord::Migration
  def self.up
    create_table :eft_batches do |t|
      t.column :for_month, :string # month #1-12 == "Time#year(2007)/Time#month(10)"
      t.column :submitted_at, :datetime
      t.column :no_eft_count, :integer
      t.column :invalid_count, :integer
      t.column :regenerate_now, :string
      t.column :last_total_regenerate, :datetime
    end
  end
  def self.down
    drop_table :eft_batches
  end
end