Thread.current['user'] = User.find(2)

# Create the report
m = MasterInventoryReport.create()
# Pull the inventory
m.pull_inventory_for_stores