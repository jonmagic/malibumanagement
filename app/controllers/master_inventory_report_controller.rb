class MasterInventoryReportController < ApplicationController

  def index
    @master_inventory_reports = MasterInventoryReport.find(:all, :order => "created_at DESC")
  end
  
  def show
    build_report(params[:id])
    render :layout => 'master_inventory_report_show'
  end
  
  def edit
    mir = MasterInventoryReport.find(params[:id])
    headers['Content-Type'] = "application/vnd.ms-excel"
    headers['Content-Disposition'] = 'attachment; filename="master_inventory_report #{mir.created_at.humanize}.xls"'
    headers['Cache-Control'] = ''
    build_report(params[:id])
    render :layout => false
  end

  private
  
    def build_report(report_id)
      @report = MasterInventoryReport.find(report_id)
      @stores = Store.find(:all)

      rows = Hash.new {|h,k| h[k] = { "row" => (k) }}

      item_inventory_codes = @report.master_inventory_items.collect { |i| i.inventory_code }.uniq
      item_inventory_codes.each do |inventory_code|
        price_list_item = MasterInventoryPriceListItem.find_by_inventory_code(inventory_code)
        rows[inventory_code]["Code"]        = inventory_code
        rows[inventory_code]["Description"] = price_list_item.description
        rows[inventory_code]["Cost"]        = price_list_item.cost_price
        rows[inventory_code]["Retail"]      = price_list_item.retail_price
        @stores.each do |store|
          rows[inventory_code][store.alias] = {}
          rows[inventory_code][store.alias]["Quantity"] = 0
          rows[inventory_code][store.alias]["Cost"]     = 0.0
          rows[inventory_code][store.alias]["Retail"]   = 0.0
        end
        rows[inventory_code]["Total Quantity"]  = 0
        rows[inventory_code]["Total Cost"]      = 0.0
        rows[inventory_code]["Total Retail"]    = 0.0
      end

      # Setup my table header
      @header = []
      @stores.each do |store|
        hash = {}
        hash[store.alias] = ["Quantity","Cost","Retail"]
        @header << hash
      end

      # Setup my table footer
      stores = Hash.new {|h,k| h[k] = { "store" => (k) }}
      @stores.each do |store|
        stores[store.alias]["Total Quantity"] = 0
        stores[store.alias]["Total Cost"]     = 0.0
        stores[store.alias]["Total Retail"]   = 0.0
      end
      @total_quantity = 0
      @total_cost     = 0.0
      @total_retail   = 0.0

      # Setup my table body
      @report.master_inventory_items.each do |item|
        price_list_item = MasterInventoryPriceListItem.find_by_inventory_code(item.inventory_code)
        quantity = item.quantity
        cost = item.quantity*price_list_item.cost_price
        retail = item.quantity*price_list_item.retail_price
        rows[item.inventory_code][item.store_name]["Quantity"]  += quantity
        rows[item.inventory_code][item.store_name]["Cost"]      += cost
        rows[item.inventory_code][item.store_name]["Retail"]    += retail
        rows[item.inventory_code]["Total Quantity"] += quantity
        rows[item.inventory_code]["Total Cost"]     += cost
        rows[item.inventory_code]["Total Retail"]   += retail
        stores[item.store_name]["Total Quantity"] += quantity
        stores[item.store_name]["Total Cost"]     += cost
        stores[item.store_name]["Total Retail"]   += retail
        @total_quantity += quantity
        @total_cost     += cost
        @total_retail   += retail
      end

      # return values to the view
      @items  = rows.values
      @footer = stores
    end

end