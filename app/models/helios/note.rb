class Helios::Note < ActiveRecord::Base
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

  include HeliosPeripheral

  set_table_name 'Notes'
  set_primary_key 'Rec_no'

  belongs_to :client, :class_name => 'Helios::ClientProfile', :foreign_key => 'Client_no'

  validates_presence_of :OTNum, :Location, :Last_Mdt, :Client_no

  # Slave functions: find, create, update, destroy, touch
  def self.find_on_master(id)
    return nil if id.nil?
    self.find_on_slave(self.master.keys[0], id)
  end
  def self.find_on_slave(slave_name, id)
    return nil if id.nil?
    self.slaves[slave_name].find(id)
  end
  def find_on_master
    self.class.find_on_master(self.id)
  end
  def find_on_slave(slave_name)
    self.class.find_on_slave(slave_name, self.id)
  end

  def self.create_on_master(attrs={})
    self.create_on_slave(self.master.keys[0], attrs)
  end
  def self.create_on_slave(slave_name, attrs={})
    attrs.stringify_keys!
    rec = self.slaves[slave_name].create({'Last_Mdt' => Time.now - 5.hours}.merge(attrs))
puts "Touching Client ##{attrs['Client_no']}"
    Helios::ClientProfile.touch_on_master(attrs['Client_no']) if attrs.has_key?('Client_no')
    return rec
  end

  # Refer to these by OTNum as id
  def self.update_on_master(id, attrs={})
    return nil if id.nil?
    self.update_on_slave(self.master.keys[0], id, attrs)
  end
  def self.update_on_slave(slave_name, id, attrs={})
    pk = self.slaves[slave_name].primary_key

    self.slaves[slave_name].primary_key = 'OTNum'
    rec = self.slaves[slave_name].new
    rec.id = id
    attrs.stringify_keys!
    {'Last_Mdt' => Time.now - 5.hours}.merge(attrs).each { |k,v| rec.send(k+'=', v) }
    success = rec.save && (attrs.has_key?('Client_no') ? Helios::ClientProfile.touch_on_master(attrs['Client_no']) : true)

    self.slaves[slave_name].primary_key = pk
    success
  end
  # * * * *
  def update_on_master(attrs={})
    self.update_on_slave(self.class.master.keys[0], attrs)
  end
  def update_on_slave(slave_name, attrs={})
    # Updating OpenHelios requires referring to a record by OTNum
    self.class.update_on_slave(slave_name, self.OTNum, {'Client_no' => self.client_no}.merge(attrs))
  end

  def self.destroy_on_master(id)
    self.update_on_master(id, :Deleted => true)
  end
  def self.destroy_on_slave(slave_name, id)
    self.update_on_slave(slave_name, id, :Deleted => true)
  end
  def destroy_on_master
    self.update_on_master(:Deleted => true)
  end
  def destroy_on_slave(slave_name)
    self.update_on_slave(slave_name, :Deleted => true)
  end

  # Refer to these by OTNum as id
  def self.touch_on_master(id)
    self.update_on_master(id)
  end
  def self.touch_on_slave(slave_name, id)
    self.update_on_master(slave_name, id)
  end
  # * * * *
  def touch_on_master
    self.update_on_master
  end
  def touch_on_slave(slave_name)
    self.update_on_slave(slave_name)
  end

  def self.next_OTNum
    self.connection.select_value("SELECT MAX(#{connection.quote_column_name('OTNum')}) AS yup FROM #{connection.quote_column_name('Transactions')}", 'yup').to_i+1
  end
end
