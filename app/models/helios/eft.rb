class Helios::Eft < ActiveRecord::Base
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

  set_table_name 'EFT'
  set_primary_key 'Client_No'

  has_one :client_profile, :class_name => 'Helios::ClientProfile', :foreign_key => 'Client_No'
  
  include HeliosPeripheral

  def self.memberships(month, render_nils=false)
    sql = case ::RAILS_ENV
    when 'development'
      "(Member1 = 'VIP' AND '"+Time.parse(month).strftime("%Y-%m-%d")+"' >= Member1_Beg AND Member1_Exp >= '"+Time.parse(month).strftime("%Y-%m-%d")+"') OR (Member2 = 'VIP' AND '"+Time.parse(month).strftime("%Y-%m-%d")+"' >= Member2_Beg AND Member2_Exp >= '"+Time.parse(month).strftime("%Y-%m-%d")+"')"
    when 'production'
      "([Member1] = 'VIP' AND '"+Time.parse(month).strftime("%Y%m%d")+"' >= [Member1_Beg] AND [Member1_Exp] >= '"+Time.parse(month).strftime("%Y%m%d")+"') OR ([Member2] = 'VIP' AND '"+Time.parse(month).strftime("%Y%m%d")+"' >= [Member2_Beg] AND [Member2_Exp] >= '"+Time.parse(month).strftime("%Y%m%d")+"')"
    end
    
    mems = []
    Helios::ClientProfile.find(:all, :conditions => [sql]).each do |cp|
      if cp.eft.nil?
        yield cp if render_nils && block_given?
      else
        if(!((!cp.eft.Freeze_Start.nil? ? cp.eft.Freeze_Start.to_date <= Time.parse(month).to_date : false) && (!cp.eft.Freeze_End.nil? ? Time.parse(month).to_date < cp.eft.Freeze_End.to_date : false)) && ((!cp.eft.Start_Date.nil? ? cp.eft.Start_Date.to_date <= Time.parse(month).to_date : true) && (!cp.eft.End_Date.nil? ? Time.parse(month).to_date < cp.eft.End_Date.to_date : true)))
          mems << cp
          yield cp if block_given?
        end
      end
    end
    
    mems
  end

  # Slave functions: find, update, destroy, touch
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

  def self.update_on_master(id, attrs={})
    self.update_on_slave(self.master.keys[0], id, attrs)
  end
  def self.update_on_slave(slave_name, id, attrs={})
    self.slaves[slave_name].primary_key = self.primary_key
    rec = self.slaves[slave_name].new
    rec.id = id
    attrs.stringify_keys!
    {'Last_Mdt' => Time.now - 5.hours}.merge(attrs).each do |k,v|
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
    self.update_on_master(slave_name, id)
  end
  def touch_on_master
    self.update_on_master
  end
  def touch_on_slave(slave_name)
    self.update_on_slave(slave_name)
  end

  def copy_to_master # UNTESTED, THOUGH ALMOST PROVEN TO WORK!!
    self.copy_to_slave(self.master.keys[0])
  end
  def copy_to_slave(slave_name) # UNTESTED, THOUGH ALMOST PROVEN TO WORK!!
    pk = self.slaves[slave_name].primary_key
    self.slaves[slave_name].primary_key = 'temporarily_bogus'
    
    rec = self.slaves[slave_name].new
    rec.attributes = self.public_attributes
    rec.Client_No = self.Client_No
    success = rec.save
    
    self.slaves[slave_name].primary_key = pk
    success
  end

  def self.delete_these(*ids)
    ids = ids.shift if ids[0].is_a?(Array)
    self.update_satellites = true
    failed_list = []
    ids.each do |id|
      begin
        eft = self.find(id)
        eft.destroy
        failed_list << id if !eft.errors.blank?
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
    puts "Retrying ONCE for #{failed_list.length} of them..."
    second_failed = []
    failed_list.each do |id|
      begin
        eft = self.find(id)
        eft.destroy
        second_failed << id if !eft.errors.blank?
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
    puts "Retrying TWICE for #{second_failed.length} of them..."
    really_failed = []
    second_failed.each do |id|
      begin
        eft = self.find(id)
        eft.destroy
        really_failed << id if !eft.errors.blank?
      rescue ActiveRecord::RecordNotFound
        nil
      end
    end
    puts " * * * * * *" * 5
    puts "FAILED TO DESTROY:"
    puts really_failed.inspect
    self.update_satellites = false
  end

  def batch!
    prev = self.find_on_master
    return false if prev.nil?

    rec = self.master[self.master.keys[0]].new
    rec.id = id
    rec.Last_Mdt = Time.now - 5.hours - 5.minutes

    self.update_attributes(:Last_Mdt => Time.now)
    self.client_profile.touch_on_master

    return rec.save
  end

  def batch_these!(*ids)
    ids = ids.shift if ids[0].is_a?(Array)
    ids.each do |id|
      begin
        self.find(id).batch!
      rescue ActiveRecord::RecordNotFound
      end
    end
  end

  def credit_card?
    !(['C','S'].include?(self.Acct_Type.to_s))
  end

  def public_attributes
    self.attributes.reject {|k,v| [self.class.primary_key, 'F_LOC', 'UpdateAll'].include?(k)}
  end
end
