class InventoryReport < ActiveRecord::Base
  require_library_or_gem 'odbc'
  has_many :inventory_line_items, :dependent => :destroy
  has_one :instance, :as => :data, :class_name => 'FormInstance' # Looks for data_id in form_instances, calls it self.instance
  has_many :logs, :as => 'object'
  attr_accessor :save_status
  cattr_accessor :odbc_error

  def items(reload=false)
    @the_inventory_items ||= nil
    return @the_inventory_items if @the_inventory_items.kind_of?(Array)
    @the_inventory_items = []
    if reload || self.inventory_line_items.length < 1
      self.inventory_line_items.each {|li| li.destroy} if reload
      theitems = self.inventory_from_open_helios
  return [] unless theitems.is_a?(Array)
      theitems.each_with_index do |line_item,i|
        next if line_item['Descriptions'].nil?
        self.inventory_line_items.build(:name => "li_#{i.to_s}", :label => line_item['Descriptions'], :should_be => line_item['qty_onhand']) unless inventory_line_item("li_#{i.to_s}")
      end
      self.save
    end
    @the_inventory_items = inventory_line_items(true) || []
  end

  def update_attributes(new_attributes)
    return if new_attributes.nil?
    attributes = new_attributes.dup
    attributes.stringify_keys!
    attributes.each do |key, value|
      set_inventory_line_item(key, value) if is_inventory_item_name?(key)
    end
  end

  def is_inventory_item_name?(name)
    !['signer_id', 'signer_hash', 'signer_date'].include?(name)
  end
  def inventory_line_item(liname)
    inventory_line_items.find_by_name(liname.columnize)
  end
  def set_inventory_line_item(liname,value)
    li = inventory_line_item(liname)
    logger.error "Trying to set #{liname} (#{liname}) to #{value}.."
    return false if li.nil?
    li.actual = value
    if li.save
      logger.error "Set #{liname} to #{value}..!"
    else
      logger.error "ERROR Setting #{liname} to #{value}..!"
    end
  end

  protected
    def inventory_from_odbc
      # ODBC::connect("HeliosInventory-#{self.instance.store.alias}", self.instance.store.alias, self.instance.store.alias.l33t.reverse) do |connection|
      results = []
      conn = ODBC::connect("HeliosInventory-#{self.instance.store.alias}", '', '')
      query = conn.prepare('SELECT Descriptions,qty_onhand FROM inventory')
      query.execute.each_hash {|h| results.push(h) }
      conn.disconnect
      ActionController::Base.logger.info results.inspect
      return results
    rescue ODBC::Error => e
      logger.error "! Error Connecting to ODBC Database (HeliosInventory-#{self.instance.store.alias})!"
      logger.error "! Error message: #{e.clean_message}"
      self.class.odbc_error = e.clean_message
      return false
    end
    def inventory_from_open_helios
      begin
        ActionController::Base.logger.info "Connecting to http://#{self.instance.store.ar_site}"
        puts "Connecting to http://#{self.instance.store.ar_site}"
        conn = ActiveResource::Connection.new("http://#{self.instance.store.ar_site}")
        resp = conn.get('/inventories.xml')
      rescue Errno::ETIMEDOUT => e
        err = "Connection Failed"
      rescue Timeout::Error => e
        err = "Connection Failed"
      rescue Errno::EHOSTDOWN => e
        err = "Connection Failed"
      ensure
        if err
          return false
        else
          ActionController::Base.logger.info resp.inspect
          # puts resp.inspect
          return resp['inventory']
        end
      end
    end
end
