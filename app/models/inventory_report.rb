class InventoryReport < ActiveRecord::Base
  has_many :inventory_line_items
end
