class MasterInventoryReport < ActiveRecord::Base
  has_many :master_inventory_items, :dependent => :destroy
  before_create :set_arrays
  
  def set_arrays
    needs_inventory_pulled = []
    Store.find(:all).each do |store|
      needs_inventory_pulled << store.alias
    end
    self.needs_inventory_pulled = needs_inventory_pulled.join(',')
    self.created_at = Time.now
  end
  
  def pull_inventory_for_stores
    (1..8).each do |loop|
      pull
      self.save
      sleep 30
    end
  end
  
  def pull
    needs_inventory_pulled = self.needs_inventory_pulled.split(",")
    needs_inventory_pulled.each do |store_name|
      store = Store.find_by_alias(store_name)
      inventory = store.pull_inventory
      if inventory != nil
        MasterInventoryItem.record_items(self, store_name, inventory)
        needs_inventory_pulled.delete(store_name)
      end
    end
    self.needs_inventory_pulled = needs_inventory_pulled.join(',')
  end
  
end