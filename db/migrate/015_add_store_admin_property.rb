class AddStoreAdminProperty < ActiveRecord::Migration
  def self.up
    add_column :users, :is_store_admin, :boolean, :default => false
  end

  def self.down
    # No real important reason to need to migrate this one down.
  end
end
