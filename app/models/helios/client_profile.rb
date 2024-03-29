class Helios::ClientProfile < ActiveRecord::Base
  # Properties:
  #   Client_no: integer
  #   Last_Name: string
  #   First_Name: string
  #   Address: string
  #   City: string
  #   State: string
  #   Zip: string
  #   HPhoneAc: string
  #   HPhone: string
  #   WPhone: string
  #   Referred: string
  #   Referred_ID: integer
  #   Bday: datetime
  #   Gender: string
  #   Mail: string
  #   CheckP: string
  #   Alert: string
  #   Auto_Draft: string
  #   Time1: decimal
  #   Time1_Exp: datetime
  #   Time1_Flex: integer
  #   Time2: decimal
  #   Time2_Exp: datetime
  #   Time2_Flex: integer
  #   Time3: decimal
  #   Time3_Exp: datetime
  #   Time3_Flex: integer
  #   Time4: decimal
  #   Time4_Exp: datetime
  #   Time4_Flex: integer
  #   Time5: decimal
  #   Time5_Exp: datetime
  #   Time5_Flex: integer
  #   Time6: decimal
  #   Time6_Exp: datetime
  #   Time6_Flex: integer
  #   Member1: string
  #   Member1_Beg: datetime
  #   Member1_Exp: datetime
  #   member1_flex: integer
  #   Member2: string
  #   Member2_Beg: datetime
  #   Member2_Exp: datetime
  #   member2_flex: integer
  #   PrePaid: decimal
  #   Bonus_Bucks: decimal
  #   Payment_Amount: decimal
  #   Balance: decimal
  #   Visits_Due: integer
  #   Date_Due: datetime
  #   Credit_Limit: decimal
  #   First_Visit: datetime
  #   Last_Visit: datetime
  #   Last_Release: datetime
  #   Service_Rev: decimal
  #   Product_Rev: decimal
  #   PIN: string
  #   Total_Rev: decimal
  #   OneTime_1: string
  #   OneTime_2: string
  #   OneTime_3: string,Once_Date1: datetime
  #   Once_Code1: string
  #   Once_Date2: datetime
  #   Once_Code2: string
  #   LastTanDate: datetime
  #   Last_Mdt: datetime
  #   FaxPhone: string
  #   Comm_Flag: string
  #   Client_Flag: string
  #   appt_noshow: integer
  #   appt_cancel: integer
  #   appt_latecancel: integer
  #   Member1_FreezeStart: datetime
  #   Member2_FreezeStart: datetime
  #   Member1_FreezeEnd: datetime
  #   Member2_FreezeEnd: datetime
  #   FIndicator: string
  #   FPrint: binary
  #   FidReg: boolean
  #   FPrint1: binary
  #   CreditP: string
  #   UserD1: string
  #   UserD2: string
  #   UserD3: string
  #   UserD4: string
  #   UserD5: string
  #   Hemail: string
  #   Wemail: string
  #   AssignedID: string
  #   Address2: string
  #   F_LOC: string
  #   AllowShare: string
  #   Deleted: boolean
  #   UpdateAll: datetime
  #   fv_cashier: text

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
  def vip_transaction(after=nil)
    after = Time.parse(Time.now.strftime("%Y/%m")) if after.nil?
    Helios::Transact.find(:first, :conditions => ["[client_no]=? AND [Last_Mdt] > ? AND [Code] LIKE ?", self.id, after, '%EFT%'], :order => '[Last_Mdt] ASC')
  end
  def vip_note(after=nil)
    after = Time.parse(Time.now.strftime("%Y/%m")) if after.nil?
    Helios::Note.find(:first, :conditions => ["[Client_no]=? AND [Last_Mdt] > ? AND [Comments] LIKE ?", self.id, after, '%EFT%'], :order => '[Last_Mdt] ASC')
  end

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

  # Slave functions: find, create, update, destroy, touch
  def self.find_on_master(id)
    self.find_on_slave(self.master.keys[0], id)
  end
  def self.find_on_slave(slave_name, id)
    self.slaves[slave_name].find(id)
  end
  def find_on_master
    self.class.find_on_master(self.id)
  end
  def find_on_slave(slave_name)
    self.class.find_on_slave(slave_name, self.id)
  end

# Commented because we shouldn't need these...
  # def self.create_on_master(attrs={})
  #   self.create_on_slave(self.master.keys[0], attrs)
  # end
  # def self.create_on_slave(slave_name, attrs={})
  #   return self.slaves[slave_name].create({:Last_Mdt => Time.now - 5.hours}.merge(attrs))
  # end

  def self.update_on_master(id, attrs={})
    self.update_on_slave(self.master.keys[0], id, attrs)
  end
  def self.update_on_slave(slave_name, id, attrs={})
    return nil if id.nil?
    self.slaves[slave_name].primary_key = self.primary_key
    rec = self.slaves[slave_name].new
    rec.id = id
    attrs.stringify_keys!
    {'Last_Mdt' => Time.now}.merge(attrs).each do |k,v|
      rec.send(k+'=', v)
    end
    rec.save
  end
  def update_on_master(attrs={})
    self.class.update_on_master(self.id, attrs)
  end
  def update_on_slave(slave_name, attrs={})
    self.class.update_on_slave(slave_name, self.id, attrs)
  end

  def self.destroy_on_master(id)
    self.find_on_master(id).destroy
  end
  def self.destroy_on_slave(slave_name, id)
    self.find_on_slave(slave_name, id).destroy
  end
  def destroy_on_master
    self.class.destroy_on_master(self.id)
  end
  def destroy_on_slave(slave_name)
    self.class.destroy_on_slave(slave_name, self.id)
  end

  def self.touch_on_master(id)
    self.update_on_master(id)
  end
  def self.touch_on_slave(slave_name, id)
    self.update_on_slave(slave_name, id)
  end
  def touch_on_master
    self.update_on_master
  end
  def touch_on_slave(slave_name)
    self.update_on_slave(slave_name)
  end

  def public_attributes
    self.attributes.reject {|k,v| [self.class.primary_key, 'F_LOC', 'UpdateAll'].include?(k)}
  end

  def self.report_membership!(id,datetime=nil) # This is to be called primarily by the commandline.
    self.find(id).report_membership!(datetime)
  end
  def report_membership!(datetime=nil)
    datetime ||= Time.now
    datetime = datetime.to_time
    date = datetime.to_date
    report = ''
    cp = nil
    cp = self if ((self.Member1 == 'VIP' && self.Member1_Beg < datetime && self.Member1_Exp >= datetime) || (self.Member2 == 'VIP' && self.Member2_Beg < datetime && self.Member2_Exp >= datetime))
    report << (cp ? "ClientProfile reports a current membership" : "ClientProfile reports no membership")
    if cp
      report.instance_variable_set(:@client, cp)
      if prepaid = cp.has_prepaid_membership?(datetime)
        report.instance_variable_set(:@prepaid, prepaid)
        report << ", but this is a prepaid membership -- #{prepaid.Code} bought on #{prepaid.Last_Mdt}!"
      else
        if cp.eft.nil?
          report << ", Client has no EFT"
        else
          report.instance_variable_set(:@eft, cp.eft)
          if(((!cp.eft.Start_Date.nil? ? cp.eft.Start_Date.to_date <= date : true) && (!cp.eft.End_Date.nil? ? date <= cp.eft.End_Date.to_date : true)) && !((!cp.eft.Freeze_Start.nil? ? cp.eft.Freeze_Start.to_date <= date : false) && (!cp.eft.Freeze_End.nil? ? date <= cp.eft.Freeze_End.to_date : false)))
              report << ", current time in EFT is valid to bill!"
          else
            report << ", current time in EFT is FROZEN!"
          end
        end
      end
    end
    report
  end

  def self.has_prepaid_membership?(id,datetime=nil)
    self.find(id).has_prepaid_membership?(datetime)
  end
  def has_prepaid_membership?(datetime=nil)
    datetime ||= Time.now
    datetime = datetime.to_time
    sql = case ::RAILS_ENV
    when 'development'
      date_s = (datetime-47088000).strftime("%Y-%m-%d")
      "(Code = 'V' OR Code = 'V199' OR Code = 'VX' OR Code = 'VY' OR Code = 'VY+' OR Code = 'V1M' OR Code = 'V1W') AND CType != ? AND CType != ? AND client_no = ? AND Last_Mdt > ?"
    when 'production'
      date_s = (datetime-47088000).strftime("%Y%m%d")
      "([Code] = 'V' OR [Code] = 'V199' OR [Code] = 'VX' OR [Code] = 'VY' OR [Code] = 'VY+' OR [Code] = 'V1M' OR [Code] = 'V1W') AND [CType] != ? AND [CType] != ? AND [client_no] = ? AND [Last_Mdt] > ?"
    end
    mem_trans = Helios::Transact.find(:all, :conditions => [sql, '1', '2', self.id, date_s])

    lasting = {
      'VY'  => datetime-36720000, # 425 days
      'VY+' => datetime-47088000, # 545 days
      'V1M' => datetime-2592000,  # 30 days
      'V1W' => datetime-604800    # 7 days
    }

    # **** Check for a later 'V' transaction
    # Gather all mem_trans that are in range (likely only one, but just in case, catch them all)
    in_range = mem_trans.select { |t| t.Code != 'V' && t.Code != 'VX' && t.Code != 'V199' && t.Last_Mdt > lasting[t.Code] }.sort {|a,b| a.Last_Mdt <=> b.Last_Mdt}
    # Make sure there isn't a Code 'V' transaction AFTER all active prepaids.
    eft_trans = mem_trans.select { |t| t.Code == 'V' || t.Code == 'VX' || t.Code == 'V199' }
    # If we have a mem_trans later than any V transactions, then we're living in a prepaid and do NOT need to bill.
    living_in_prepaid = !in_range.empty? # true if not empty, false if empty
    if living_in_prepaid && !eft_trans.empty?
      living_in_prepaid = in_range.all? do |ir|
        eft_trans.all? do |et|
          ir.Last_Mdt > et.Last_Mdt
        end
      end
    end
    # ****

    # If membership, return the most recently purchased prepaid membership
    return living_in_prepaid ? in_range.last : false
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
    self.update_satellites = false
  end

  def remove_vip!
    # Delete eft from all locations
    # Delete eft from server
puts "Deleting from stores..."
    puts Helios::Eft.delete_these(self.eft.id) if self.eft
    # Update the cp fields like Member1 on the server
    if(self.Member1 == 'VIP')
      self.update_attributes(
        :Member1 => '',
        :Member1_Beg => '',
        :Member1_Exp => '',
        :Member1_FreezeStart => '',
        :Member1_FreezeEnd => '',
        :UpdateAll => Time.now
      )
    elsif(self.Member2 == 'VIP')
      self.update_attributes(
        :Member2 => '',
        :Member2_Beg => '',
        :Member2_Exp => '',
        :Member2_FreezeStart => '',
        :Member2_FreezeEnd => '',
        :UpdateAll => Time.now
      )
    end
    return true
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
