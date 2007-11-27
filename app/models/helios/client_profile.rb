class Helios::ClientProfile < ActiveRecord::Base
  @nologging = true

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
      :mode => 'ADO',
      :database => 'HeliosBS',
      :security => 'trusted'
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
    sql = case ::RAILS_ENV
    when 'development'
      "SELECT * FROM Client_Profile #{craft_sql_condition_for_query(query)} ORDER BY Client_no ASC LIMIT #{limit} OFFSET #{offset}"
    when 'production'
      "SELECT * FROM (SELECT TOP #{limit} * FROM (SELECT TOP #{limit + offset} * FROM Client_Profile #{craft_sql_condition_for_query(query)} ORDER BY [Client_no] ASC) AS tmp1 ORDER BY [Client_no] DESC) AS tmp2 ORDER BY [Client_no] ASC"
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

  def self.find_on_master(id)
    self.master[self.master.keys[0]].find(id)
  end

  def self.destroy_on_master(id)
    self.find_on_master(id).destroy
  end

  def self.touch_on_master(id)
    rec = self.master[self.master.keys[0]].new
    rec.id = id
    rec.Last_Mdt = Time.now - 5.hours
    rec.save
  end

  def public_attributes
    self.attributes.reject {|k,v| [self.class.primary_key, 'F_LOC', 'UpdateAll'].include?(k)}
  end

  def self.has_prepaid_membership?(id)
    self.find(id).has_prepaid_membership?
  end

  def has_prepaid_membership?
    sql = case ::RAILS_ENV
    when 'development'
      "(Code = 'VY' OR Code = 'VY+' OR Code = 'V1M' OR Code = 'V1W') AND client_no = ? AND Last_Mdt > ?"
    when 'production'
      "([Code] = 'VY' OR [Code] = 'VY+' OR [Code] = 'V1M' OR [Code] = 'V1W') AND [client_no] = ? AND [Last_Mdt] > ?"
    end
    mem_trans = Helios::Transact.find(:all, :conditions => [sql, self.id, Time.now-47088000])
    lasting = {
      'VY'  => Time.now-36720000, # 425 days
      'VY+' => Time.now-47088000, # 545 days
      'V1M' => Time.now-2592000,  # 30 days
      'V1W' => Time.now-604800    # 7 days
    }
    mem_trans.each do |t|
      return true if t.Last_Mdt > lasting[t.Code]
    end
    return false
  end

  def self.fixmismatch
    count = 0
    update_satellites = false # Ensures satellite databases are NOT updated automatically.
    find_all_by_member1_flex(nil).each {|faulty| count += 1 if faulty.update_attributes(:member1_flex => 0) }
    find_all_by_member2_flex(nil).each {|faulty| count += 1 if faulty.update_attributes(:member2_flex => 0) }
    count
  end

  def self.delete_these(ids)
    self.update_satellites = true
    failed_list = []
    ids.each do |id|
      begin
        cp = self.find(id)
        cp.destroy
        failed_list << id if !cp.errors.blank?
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
    puts "Retrying ONCE for #{failed_list.length} of them..."
    second_failed = []
    failed_list.each do |id|
      begin
        cp = self.find(id)
        cp.destroy
        second_failed << id if !cp.errors.blank?
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
    puts "Retrying TWICE for #{second_failed.length} of them..."
    really_failed = []
    second_failed.each do |id|
      begin
        cp = self.find(id)
        cp.destroy
        really_failed << id if !cp.errors.blank?
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
    puts " * * * * * *" * 5
    puts "FAILED TO DESTROY:"
    puts really_failed.inspect
  end

  def remove_vip!
    if(self.Member1 == 'VIP')
      self.update_attributes(:Member1 => '', :Member1_Beg => '', :Member1_Exp => '', :Member1_FreezeStart => '', :Member1_FreezeEnd => '')
    elsif(self.Member2 == 'VIP')
      self.update_attributes(:Member2 => '', :Member2_Beg => '', :Member2_Exp => '', :Member2_FreezeStart => '', :Member2_FreezeEnd => '')
    end
    Helios::Eft.delete_these([self.eft.id]) if self.eft
    true
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
