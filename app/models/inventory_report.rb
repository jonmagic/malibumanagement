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
      # self.inventory_line_items.each {|li| li.destroy}
      theitems = self.inventory_from_open_helios
      return @the_inventory_items unless theitems
      theitems.each do |line_item|
        next if line_item['Descriptions'].nil?
        self.inventory_line_items.build(:name => line_item['Descriptions'].columnize, :label => line_item['Descriptions'], :should_be => line_item['qty_onhand']) unless self.inventory_line_item(line_item['Descriptions'])
      end
      self.save
    end
    @the_inventory_items = self.inventory_line_items(true)
  end

  def update_attributes(attributes)
    attributes.each do |key, value|
logger.error "Setting #{key} to #{value}:"
      self.set_inventory_line_item(key, value) if self.is_inventory_item_name?(key)
    end
  end

  def is_inventory_item_name?(name)
    ['signer_id', 'signer_hash', 'signer_date'].include?(name) ? false : true
  end
  def inventory_line_item(liname)
    self.inventory_line_items.find_by_name(liname.columnize)
  end
  def set_inventory_line_item(liname,value)
    li = self.inventory_line_items.find_by_name(liname.columnize)
    logger.error "Trying to set #{liname} to #{value}.."
    return false if li.nil?
    li.actual = value
    logger.error "Set #{liname} to #{value}..!"
    li.save
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
      results = {}
      begin
        ActionController::Base.logger.info "Connecting to http://#{self.instance.store.ar_site}"
        puts "Connecting to http://#{self.instance.store.ar_site}"
        conn = ActiveResource::Connection.new("http://#{self.instance.store.ar_site}")
        results = conn.get('/inventories')
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
          ActionController::Base.logger.info results['inventory'].inspect
          puts results['inventory'].inspect
          return results['inventory']
        end
      end
    end
end
