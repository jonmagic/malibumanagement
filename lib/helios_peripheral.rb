#Hmmm.. I *could* extend the hosting model to record its actions and then a function here could 'catch up' on all the satellite locations when instructed. 

module DbMethods
  def add_slave(location, uri_base)
    @slaves ||= {}
    @slaves[location] = ActiveResource::Struct.new do |client_profile|
      client_profile.uri = "http://#{uri_base}/client_profiles"
      # client_profile.credentials :name => "me", :password => "password"
    end
  end

  def propogate_method(method, *args)
    retval = []
    @slaves.each do |slave|
      retval << slave.send(method, *args)
    end
    retval
  end
end

module HeliosPeripheral
  def self.append_features(base)
    base.extend DbMethods
    base.cattr_accessor :update_satellites
    base.update_satellites = false
    base.cattr_accessor :journal
    base.journal = []
    SATELLITE_LOCATIONS.keys.each do |location|
      base.add_slave(location, SATELLITE_LOCATIONS[location])
    end

    # Register the after_save handles
    base.after_save do |record|
      if self.class.update_satellites
        satellite_records = self.propogate_method(:find, record.id)
        satellite_records.update_attributes(record.attributes)
      else
        @journal << {:save => record.attributes}
      end
    end
    base.before_destroy do |record|
      if self.class.update_satellites
        satellite_records = self.propogate_method(:find, record.id)
        satellite_records.destroy
      else
        @journal << {:destroy => record.id}
      end
    end
    # * * * *
  end
end
