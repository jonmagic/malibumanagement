class Helios::Eft < ActiveRecord::Base
  # self.establish_connection(
  #   :adapter  => 'mysql',
  #   :database => 'HeliosBS',
  #   :host     => '10.11.45.3',
  #   :username => 'maly',
  #   :password => 'booboo'
  # )
  self.establish_connection(
    :adapter  => 'sqlserver',
    :mode => 'ODBC',
    :dsn => 'HeliosBS'
  )

  set_table_name 'EFT'
  set_primary_key 'Client_No'

  include HeliosPeripheral

  def public_attributes
    self.attributes.reject {|k,v| [self.class.primary_key, 'F_LOC', 'UpdateAll'].include?(k)}
  end
end
