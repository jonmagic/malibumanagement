class InventoryLineItem < ActiveRecord::Base
  belongs_to :inventory_report
end