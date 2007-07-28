class Helios::ClientProfile < ActiveRecord::Base
  self.establish_connection(
    :adapter  => 'mysql',
    :database => 'HeliosBS',
    :host     => '127.0.0.1',
    :username => 'OpenHeliosConnector',
    :password => 'adshf98a4yaw'
  )

  set_table_name 'Client_Profile'
  set_primary_key 'Client_no'

  has_many :transactions, :class_name => 'Helios::Transact', :foreign_key => 'client_no', :order => 'Last_Mdt DESC'

  include HeliosPeripheral

  def self.search(query, options={})
    limit = options[:limit] || 10
    offset = options[:offset] || 0
    self.find_by_sql("SELECT * FROM #{self.table_name} #{craft_sql_condition_for_query(query)} LIMIT #{limit} OFFSET #{offset}")
  end
  def self.search_count(query)
    self.count_by_sql("SELECT COUNT(*) FROM #{self.table_name} #{craft_sql_condition_for_query(query)}")
  end

  def full_name
    (self.First_Name.to_s + self.Last_Name.to_s).length > 1 ? self.First_Name.to_s + ' ' + self.Last_Name.to_s : '&lt;no name&gt;'
  end
  def home_phone
    (!self.HPhone.blank? && !self.HPhoneAc.blank? && (self.HPhoneAc.to_s + self.HPhone.to_s).length > 1) ? '(' + self.HPhoneAc.to_s + ') ' + self.HPhone[0,3] + '-' + self.HPhone[3,4] : '(phone)'
  end

  def last_transaction
    self.transactions.find(:first)
  end

  def public_attributes
    self.attributes.reject {|k,v| [self.class.primary_key, 'F_LOC', 'UpdateAll'].include?(k)}
  end

  protected
    def self.craft_sql_condition_for_query(query) #search in: Client_no, First_Name, Last_Name, Address
      query = '%' + query + '%'
      self.replace_bind_variables("WHERE Client_no LIKE ? OR CONCAT_WS(' ', First_Name, Last_Name) LIKE ? OR CONCAT_WS(', ', Last_Name, First_Name) LIKE ? OR Address LIKE ? ORDER BY Last_Name, First_Name", [query, query, query, query])
    end
end
