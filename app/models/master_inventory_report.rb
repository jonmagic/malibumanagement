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
    try = 0
    if self.needs_inventory_pulled != "" && try < 30
      pull
      self.save
      try += 1
    else
      self.destroy
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