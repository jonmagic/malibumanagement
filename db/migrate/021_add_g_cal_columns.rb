class AddGCalColumns < ActiveRecord::Migration
  def self.up
    add_column :stores, :gcal_url, :string
  end

  def self.down
    remove_column :stores, :gcal_url
  end
end
