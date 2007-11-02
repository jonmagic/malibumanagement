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

  def self.update_on_master(attrs)
    self.master[self.master.keys[0]].primary_key = 'OTNum'
    t = self.master[self.master.keys[0]].new
    attrs.stringify_keys!
    t.id = attrs.delete('id') || attrs.delete('OTNum')
    attrs.merge('Last_Mdt' => Time.now - 4.hours).each do |k,v|
      t.send(k+'=', v)
    end
    t.save && attrs.has_key?('Client_no') && Helios::ClientProfile.touch_on_master(attrs['Client_no'])
    t.id
  end
  def update_on_master(attrs)
    self.class.update_on_master({:Rec_no => self.id, :Client_no => self.Client_no}.merge(attrs))
  end
end