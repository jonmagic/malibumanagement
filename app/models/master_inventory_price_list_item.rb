class MasterInventoryPriceListItem < ActiveRecord::Base
  validates_presence_of :inventory_code
  validates_uniqueness_of :inventory_code
  
  def self.items_missing_prices(report_id)
    empty_items = []
    MasterInventoryPriceListItem.find(:all, :conditions => {:cost_price => nil}).each { |item| empty_items << item }
    MasterInventoryPriceListItem.find(:all, :conditions => {:retail_price => nil}).each { |item| empty_items << item }

    inventory_codes = empty_items.collect { |r| r.inventory_code }.uniq
    report_empty_items = []
    inventory_codes.each do |inventory_code|
      if MasterInventoryItem.find(:first, :conditions => {:master_inventory_report_id => report_id, :inventory_code => inventory_code})
        report_empty_items << MasterInventoryPriceListItem.find_by_inventory_code(inventory_code)
      end
    end
    return report_empty_items
  end
  
end