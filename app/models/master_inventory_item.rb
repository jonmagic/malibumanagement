class MasterInventoryItem < ActiveRecord::Base
  belongs_to :master_inventory_report
  validates_presence_of :master_inventory_report_id, :store_name, :inventory_code, :quantity
  # validates_uniqueness_of :inventory_code, :if => :same_store_and_report?
  
  # def same_store_and_report?
  #   m = MasterInventoryItem.find(:first, :conditions => {:master_inventory_report_id => master_inventory_report_id, :store_name => store_name, :inventory_code => inventory_code})
  #   m ? false : true
  # end
  
  def self.record_items(report, store_name, inventory)
    inventory["inventories"]["inventory"].each do |item|
      if MasterInventoryItem.create( :master_inventory_report => report, 
                                  :store_name => store_name, 
                                  :inventory_code => item["inv_code"], 
                                  :quantity => item["qty_onhand"])
        MasterInventoryPriceListItem.create(:inventory_code => item["inv_code"], :description => item["Descriptions"])
      end
    end
  end
  
  protected
    def validate
      errors.add("quantity", "quantity is nil") unless quantity != nil
      if quantity
        errors.add("quantity", "has no quantity") unless quantity > 0
      end
      m = MasterInventoryItem.find(:first, :conditions => {:master_inventory_report_id => master_inventory_report_id, :store_name => store_name, :inventory_code => inventory_code})
      if m
        errors.add("inventory_code", "code already exists")
      end
    end
end
