class AddStoreAdminProperty < ActiveRecord::Migration
  def self.up
    add_column :users, :is_store_admin, :boolean, :default => false
  end

  def self.down
    remove_column :users, :is_store_admin
  end
end
