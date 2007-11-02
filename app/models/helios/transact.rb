class Helios::Transact < ActiveRecord::Base
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

  def self.create_on_master(attrs)
    rec = self.master[self.master.keys[0]].create(attrs.merge(:ticket_no => self.next_ticket_no, :Last_Mdt => Time.now - 4.hours))
    Helios::ClientProfile.touch_on_master(attrs[:client_no])
    rec.id
  end
  def self.update_on_master(attrs)
    t.class.primary_key = 'OTNum'
    t = self.master[self.master.keys[0]].new
    attrs.stringify_keys!
    t.id = attrs.delete('id') || attrs.delete('OTNum')
    attrs.merge('Last_Mdt' => Time.now - 4.hours).each do |k,v|
      t.send(k+'=', v)
    end
    t.save && attrs.has_key?('client_no') && Helios::ClientProfile.touch_on_master(attrs['client_no'])
    t.id
  end
  def update_on_master(attrs)
    self.class.update_on_master(:OTNum => self.OTNum, :client_no => self.client_no)
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
