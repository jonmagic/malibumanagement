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

  validates_presence_of :OTNum, :ticket_no
  before_save do |record|
    record.OTNum = record.class.next_OTNum
    record.ticket_no = record.class.next_ticket_no
  end

  include HeliosPeripheral

  belongs_to :client, :class_name => 'Helios::ClientProfile', :foreign_key => 'client_no'

  def self.next_OTNum
    self.connection.select_value('SELECT MAX([OTNum]) AS yup FROM Transactions', 'yup').to_i+1
  end
  def self.next_ticket_no
    last = self.connection.select_value('SELECT MAX([ticket_no]) AS yup FROM Transactions WHERE [ticket_no] > 990000000', 'yup').to_i
    last = 990000000 if last == 0
    last+1
  end
  
  def self.accepted_ach
    # transact_no, ticket_no, client_no, Last_Name, First_Name, Last_Mdt, Code, Descriptions, 
  end

  def self.declined_ach
  end
  
  def self.accepted_credit
  end
  
  def self.declined_credit
  end
  
  def self.invalid_eft
  end
end
