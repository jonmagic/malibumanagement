class RemoveActivationFeatures < ActiveRecord::Migration
  def self.up
    remove_column :admins,  :activation_code
    remove_column :users,   :activation_code
  end

  def self.down
    add_column :admins, :activation_code, :string
    add_column :users,  :activation_code, :string
  end
end
