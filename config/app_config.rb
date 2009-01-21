# Configuration for how to display the application
APP_CONFIG = {
  :FEATURES => [
    :stores,
    :forms,
    # :work_schedules,
    # :bulletin_board,
	  :open_helios,
    # :eft,
	  nil
  ]
}

ZONE = {
  :Division => 2,
  :Department => 7,
  :Location_Bits => 2,
  :IP => '71.229.67.41',
  :StandardMembershipPrice => 19.99,
  :SFTP => {
    :host => 'sftp.malibu-tanning.com',
    :username => 'malibu',
    :password => 'gn1nn4t',
    :path => "/home/malibu/gotobilling/"
  },
  :DCAS_SFTP => {
    :host => 'ftp.dcas.net',
    :incoming_path => 'incoming',
    :outgoing_path => 'outgoing'
  }
}

LOCATIONS = {
  '020' => {
    :name => 'Market Center',
    :domain => 'marketcenter',
    :master => true,
    :open_helios => '192.168.20.21:5050',
    :dcas => {
      :company_alias => 'malibuinc',
      :company_user => 'malibumcVT',
      :company_pass => 'ey2DS72Qbm',
      :host => ZONE[:DCAS_SFTP][:host],
      :username => 'malibumc',
      :password => 'ChESa5ap',
      :outgoing_path => ZONE[:DCAS_SFTP][:outgoing_path],
      :incoming_path => ZONE[:DCAS_SFTP][:incoming_path],
    },
    :merchant_id => '236004',
    :merchant_pin => 'g3tbr0nz3'
  },
  '021' => {
    :name => 'Linway',
    :domain => 'linway',
    :open_helios => '192.168.21.21:5050',
    :dcas => {
      :company_alias => 'malibuinc',
      :company_user => 'malibulwVT',
      :company_pass => '7PX7jMvhQ1',
      :host => ZONE[:DCAS_SFTP][:host],
      :username => 'malibulw',
      :password => '9huyAqup',
      :outgoing_path => ZONE[:DCAS_SFTP][:outgoing_path],
      :incoming_path => ZONE[:DCAS_SFTP][:incoming_path],
    },
    :merchant_id => '236005',
    :merchant_pin => 'g3tbr0nz3'
  },
  '022' => {
    :name => 'SixSpan',
    :domain => 'sixspan',
    :open_helios => '192.168.22.21:5050',
    :dcas => {
      :company_alias => 'malibuinc',
      :company_user => 'malibussVT',
      :company_pass => 'T58TI4VHqd',
      :host => ZONE[:DCAS_SFTP][:host],
      :username => 'malibuss',
      :password => 'dru4eWAw',
      :outgoing_path => ZONE[:DCAS_SFTP][:outgoing_path],
      :incoming_path => ZONE[:DCAS_SFTP][:incoming_path],
    },
    :merchant_id => '236007',
    :merchant_pin => 'g3tbr0nz3'
  },
  '023' => {
    :name => 'Cassopolis',
    :domain => 'cassopolis',
    :open_helios => '192.168.23.21:5050',
    :dcas => {
      :company_alias => 'malibuinc',
      :company_user => 'malibucassVT',
      :company_pass => '102ES8GRbn',
      :host => ZONE[:DCAS_SFTP][:host],
      :username => 'malibucass',
      :password => 'Wun9swer',
      :outgoing_path => ZONE[:DCAS_SFTP][:outgoing_path],
      :incoming_path => ZONE[:DCAS_SFTP][:incoming_path],
    },
    :merchant_id => '236008',
    :merchant_pin => 'g3tbr0nz3'
  },
  '024' => {
    :name => 'Osceola',
    :domain => 'osceola',
    :open_helios => '192.168.24.21:5050',
    :dcas => {
      :company_alias => 'malibuinc',
      :company_user => 'malibuocVT',
      :company_pass => 'L25LB14Yiu',
      :host => ZONE[:DCAS_SFTP][:host],
      :username => 'malibuoc',
      :password => 'dus7UpRu',
      :outgoing_path => ZONE[:DCAS_SFTP][:outgoing_path],
      :incoming_path => ZONE[:DCAS_SFTP][:incoming_path],
    },
    :merchant_id => '236009',
    :merchant_pin => 'g3tbr0nz3'
  },
  '025' => {
    :name => 'UC',
    :domain => 'university',
    :open_helios => '192.168.25.21:5050',
    :dcas => {
      :company_alias => 'malibuinc',
      :company_user => 'malibuucVT',
      :company_pass => 'oKS5eHqcL8',
      :host => ZONE[:DCAS_SFTP][:host],
      :username => 'malibuuc',
      :password => 'buNu4w8q',
      :outgoing_path => ZONE[:DCAS_SFTP][:outgoing_path],
      :incoming_path => ZONE[:DCAS_SFTP][:incoming_path],
    },
    :merchant_id => '236010',
    :merchant_pin => 'g3tbr0nz3'
  },
  '026' => {
    :name => 'Granger',
    :domain => 'granger',
    :open_helios => '192.168.26.21:5050',
    :dcas => {
      :company_alias => 'malibuinc',
      :company_user => 'malibugrVT',
      :company_pass => '6nu62k61OA',
      :host => ZONE[:DCAS_SFTP][:host],
      :username => 'malibugr',
      :password => 'fRu5EyEj',
      :outgoing_path => ZONE[:DCAS_SFTP][:outgoing_path],
      :incoming_path => ZONE[:DCAS_SFTP][:incoming_path],
    },
    :merchant_id => '236011',
    :merchant_pin => 'g3tbr0nz3'
  },
  '027' => {
    :name => 'Goshen Commons',
    :domain => 'goshencommons',
    :open_helios => '192.168.27.21:5050',
    :dcas => {
      :company_alias => 'malibuinc',
      :company_user => 'malibugcVT',
      :company_pass => '2c3FUy26dO',
      :host => ZONE[:DCAS_SFTP][:host],
      :username => 'malibugc',
      :password => '9ug6hAza',
      :outgoing_path => ZONE[:DCAS_SFTP][:outgoing_path],
      :incoming_path => ZONE[:DCAS_SFTP][:incoming_path],
    },
    :merchant_id => '236006',
    :merchant_pin => 'g3tbr0nz3'
  }
}
