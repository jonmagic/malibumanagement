class Helios::Transact < ActiveRecord::Base
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

  set_table_name 'Transactions'
  set_primary_key 'transact_no'

  validates_presence_of :OTNum, :ticket_no, :transact_no, :Last_Mdt, :Modified
  validates_length_of :Descriptions, :maximum => 25 if :has_descriptions

  validates_presence_of :Descriptions, :client_no, :Last_Name, :First_Name, :Code, :CType, :Division, :Department, :Price
  # validates_presence_of :one_of => :Check, :Charge, :Credit

  def before_validation_on_create
    self.OTNum ||= self.class.next_OTNum
    self.ticket_no ||= self.class.next_ticket_no
  end
  def before_validation
    # Set Last_Mdt and possibly Modified
    self.Modified = self.Last_Mdt if !self.Last_Mdt.nil?
    self.Last_Mdt = Time.now
  end

  include HeliosPeripheral

  belongs_to :client, :class_name => 'Helios::ClientProfile', :foreign_key => 'client_no'

  alias :public_attributes :attributes

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

  def self.create_on_master(attrs={})
    self.create_on_slave(self.master.keys[0], attrs)
  end
  def self.create_on_slave(slave_name, attrs={})
    rec = self.slaves[slave_name].create({:ticket_no => self.next_ticket_no, :Last_Mdt => Time.now}.merge(attrs))
    Helios::ClientProfile.touch_on_master(attrs[:client_no])
    return rec
  end

  # Refer to these by OTNum as id
  def self.update_on_master(id, attrs={})
    self.update_on_slave(self.master.keys[0], id, attrs)
  end
  def self.update_on_slave(slave_name, id, attrs={})
    pk = self.slaves[slave_name].primary_key

    self.slaves[slave_name].primary_key = 'OTNum'
    rec = self.slaves[slave_name].new
    rec.id = id
    attrs.stringify_keys!
    {'Last_Mdt' => Time.now}.merge(attrs).each { |k,v| rec.send(k+'=', v) }
    success = rec.save && (attrs.has_key?('client_no') ? Helios::ClientProfile.touch_on_master(attrs['client_no']) : true)

    self.slaves[slave_name].primary_key = pk
    success
  end
  # * * * *
  def update_on_master(attrs={})
    self.update_on_slave(self.class.master.keys[0], attrs)
  end
  def update_on_slave(slave_name, attrs={})
    # Updating OpenHelios requires referring to a record by OTNum
    self.class.update_on_slave(slave_name, self.OTNum, {'client_no' => self.client_no}.merge(attrs))
  end

  def self.destroy_on_master(id)
    self.update_on_master(id, :CType => 1)
  end
  def self.destroy_on_slave(slave_name, id)
    self.update_on_slave(slave_name, id, :CType => 1)
  end
  def destroy_on_master
    self.update_on_master(:CType => 1)
  end
  def destroy_on_slave(slave_name)
    self.update_on_slave(slave_name, :CType => 1)
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
  def self.next_ticket_no
    last = self.connection.select_value("SELECT MAX(#{connection.quote_column_name('ticket_no')}) AS yup FROM #{connection.quote_column_name('Transactions')} WHERE #{connection.quote_column_name('ticket_no')} > 990000000", 'yup').to_i
    last = 990000000 if last == 0
    last+1
  end
  
  private
    def has_descriptions
      !self.Descriptions.nil?
    end
end
