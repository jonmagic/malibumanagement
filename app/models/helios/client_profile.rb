class Helios::ClientProfile < ActiveRecord::Base
  case ::RAILS_ENV
  when 'development'
    self.establish_connection(
      :adapter  => 'mysql',
      :database => 'HeliosBS',
      :host     => 'localhost',
      :username => 'maly',
      :password => 'booboo'
    )
  when 'production'
    self.establish_connection(
      :adapter  => 'sqlserver',
      :mode => 'ODBC',
      :dsn => 'HeliosBS'
    )
  end

  set_table_name 'Client_Profile'
  set_primary_key 'Client_no'

  has_many :transactions, :class_name => 'Helios::Transact', :foreign_key => 'client_no', :order => 'Last_Mdt DESC'
  has_one :eft, :class_name => 'Helios::Eft', :foreign_key => 'Client_no'

  include HeliosPeripheral

  def self.search(query, options={})
    limit = options[:limit] || 10
    offset = options[:offset] || 0
    case ::RAILS_ENV
    when 'development'
      sql = "SELECT * FROM Client_Profile #{craft_sql_condition_for_query(query)} ORDER BY Client_no ASC LIMIT #{limit} OFFSET #{offset}"
    when 'production'
      sql = "SELECT * FROM (SELECT TOP #{limit} * FROM (SELECT TOP #{limit + offset} * FROM Client_Profile #{craft_sql_condition_for_query(query)} ORDER BY [Client_no] ASC) AS tmp1 ORDER BY [Client_no] DESC) AS tmp2 ORDER BY [Client_no] ASC"
    end
    ActionController::Base.logger.info "Search SQL: #{sql}"
    self.find_by_sql(sql)
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

  def self.fixmismatch
    count = 0
    update_satellites = false # Ensures satellite databases are NOT updated automatically.
    find_all_by_member1_flex(nil).each {|faulty| count += 1 if faulty.update_attributes(:member1_flex => 0) }
    find_all_by_member2_flex(nil).each {|faulty| count += 1 if faulty.update_attributes(:member2_flex => 0) }
    count
  end

  protected
    def self.craft_sql_condition_for_query(query) #search in: Client_no, First_Name, Last_Name, Address
      query = '%' + query + '%'
      case ::RAILS_ENV
      when 'development'
        self.replace_named_bind_variables("WHERE Client_no LIKE :query OR First_Name LIKE :query OR Last_Name LIKE :query OR Address LIKE :query", {:query => query})
      when 'production'
        self.replace_named_bind_variables("WHERE [Client_no] LIKE :query OR [First_Name] LIKE :query OR [Last_Name] LIKE :query OR [Address] LIKE :query", {:query => query})
      end
    end
end
