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

  include HeliosPeripheral

  set_table_name 'Notes'
  set_primary_key 'Rec_no'

  belongs_to :client, :class_name => 'Helios::ClientProfile', :foreign_key => 'Client_no'

  validates_presence_of :OTNum, :Location, :Last_Mdt, :Client_no

  def self.create_on_master(attrs)
    rec = self.master[self.master.keys[0]].create(attrs.merge(:Last_Mdt => Time.now - 4.hours))
    rec.id
  end
end