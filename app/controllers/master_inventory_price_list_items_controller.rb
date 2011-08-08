class MasterInventoryPriceListItemsController < ApplicationController
  layout false
  
  def index
    if params[:master_inventory_report_id]
      # renders a page for editing only missing items
      @items = MasterInventoryPriceListItem.items_missing_prices(params[:master_inventory_report_id])
      @items = @items.sort_by {|item| item.description.to_s }
    else
      # renders a page for editing the entire list
      @items = MasterInventoryPriceListItem.find(:all)
      @items = @items.sort_by {|item| item.description.to_s }
      render :layout => 'master_inventory_price_list'
    end
  end
  
  def update
    @item = MasterInventoryPriceListItem.find(params[:id])
    if @item.update_attributes(params[:item])
      render :nothing => true
    else
      render :nothing => true, :status => 500
    end
  end
  
  def destroy
    @item = MasterInventoryPriceListItem.find(params[:id])
    if @item.destroy
      if params[:master_inventory_report_id]
        MasterInventoryItem.find(:all, :conditions => {:report_id => params[:report_id], :inventory_code => @item.inventory_code}).each do |item|
          item.destroy
        end
      else
        MasterInventoryItem.find(:all, :conditions => {:inventory_code => @item.inventory_code}).each do |item|
          item.destroy
        end
      end
      render :nothing => true, :status => 200
    else
      render :nothing => true, :status => 500
    end
  end
  
end