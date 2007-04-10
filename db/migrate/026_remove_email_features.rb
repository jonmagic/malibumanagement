class RemoveEmailFeatures < ActiveRecord::Migration
  def self.up
    remove_column :admins,  :email
    remove_column :users,   :email
  end

  def self.down
    add_column :admins, :email, :string
    add_column :users,  :email, :string
  end
end
