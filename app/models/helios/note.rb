class Helios::Note < ActiveRecord::Base
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

  set_table_name 'Notes'
  set_primary_key 'transact_no'

  belongs_to :client, :class_name => 'Helios::ClientProfile', :foreign_key => 'client_no'

  validates_presence_of :OTNum, :Location, :Last_Mdt

  def self.create_on_master(attrs)
    self.master[self.master.keys[0]].create(attrs.merge(:Last_Mdt => Time.now - 4.hours, :Location => LOCATIONS.reject {|k,v| v[:name] != self.master.keys[0]}.keys[0] ))
    Helios::ClientProfile.touch_on_master(attrs[:client_no])
  end

  def self.for_invalid_transaction(transaction_or_id)
    transact = transaction_or_id.is_a?(Helios::Transact) ? transaction_or_id : Helios::Transact.find(transaction_or_id)
    # Client_no -> from transaction
    # Last_Name
    # First_Name
    # Comments
    # EmpCode
    # Interrupt
    # Deleted -> false
    # Location
    # OTNum
  end

end