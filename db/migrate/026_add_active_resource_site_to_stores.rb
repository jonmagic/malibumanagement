class AddActiveResourceSiteToStores < ActiveRecord::Migration
  def self.up
    add_column :stores, :ar_site, :string
  end

  def self.down
    remove_column :stores, :ar_site
  end
end
