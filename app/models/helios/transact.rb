class Helios::Transact < ActiveRecord::Base
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

  set_table_name 'Transactions'
  set_primary_key 'transact_no'

  include HeliosPeripheral

  belongs_to :client, :class_name => 'Helios::ClientProfile', :foreign_key => 'client_no'
end
