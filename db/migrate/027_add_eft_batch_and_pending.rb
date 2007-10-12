class AddEftBatchAndPending < ActiveRecord::Migration
  def self.up
    create_table :eft_batches do |t|
      t.column :for_month, :string # month #1-12 == "Time#year(2007)/Time#month(10)"
      t.column :submitted_at, :datetime
      t.column :submitted_by, :integer
      t.column :eft_count, :integer
      t.column :eft_total, :integer
      t.column :eft_count_by_location, :string, :default => {}.to_yaml
      t.column :eft_count_by_amount, :string, :default => {}.to_yaml
      t.column :eft_total_by_location, :string, :default => {}.to_yaml
      t.column :memberships_without_efts, :integer
      t.column :members_with_invalid_efts, :integer
    end
    create_table :pending_efts do |t|
      t.column :eft_batch_id, :integer
      t.column :client_profile_id, :integer
      t.column :amount, :integer # Number stored in cents
    end
  end
  def self.down
    drop_table :eft_batches
    drop_table :pending_efts
  end
end