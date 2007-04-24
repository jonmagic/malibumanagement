class AddStoreAdminProperty < ActiveRecord::Migration
  def self.up
    add_column :users, :is_store_admin, :boolean, :default => false
    @migrating = true
    Store.find(:all).each do |store|
      store.users.each do |user|
        user.is_store_admin = false
        user.operation = 'attr_update'
        user.save!
      end
      admin = store.vintage_admin
      admin.is_store_admin = true
      admin.operation = 'attr_update'
      admin.save!
    end
  end

  def self.down
    remove_column :users, :is_store_admin
  end
end

class Hash < Object
# Given self and a hash, return the duplicate keys with different values
  def changed_values(hash)
    new_attribs = {}
    self.merge(hash.reject {|k,v| k=='updated_at'}) {|key,old,nw| new_attribs[key] = old unless old == nw}
    new_attribs
  end
end
