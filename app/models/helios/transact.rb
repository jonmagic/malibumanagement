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

  validates_presence_of :OTNum

  include HeliosPeripheral

  belongs_to :client, :class_name => 'Helios::ClientProfile', :foreign_key => 'client_no'
  
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
