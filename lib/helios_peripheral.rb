#Hmmm.. I *could* extend the hosting model to record its actions and then a function here could 'catch up' on all the satellite locations when instructed. 

module HeliosPeripheral
  def self.append_features(base)
    # base.extend DbMethods
    base.cattr_accessor :update_satellites
    base.update_satellites = false
    base.cattr_accessor :slaves
    base.slaves = {}
    base.cattr_accessor :journal
    base.journal = []

    def base.add_slave(location_name, uri_base)
      self.slaves ||= {}
      self.slaves[location_name] = Class.new(ActiveResource::Base)
      self.slaves[location_name].site = "http://#{uri_base}/"
      self.slaves[location_name].primary_key = self.primary_key
      self.slaves[location_name].element_name = self.name.split("::").last.underscore
    end

# Helios::ClientProfile.update_satellites = true
# cp = Helios::ClientProfile.find(1000001)
# cp.save

    def base.propogate_method(method, *args)
      retval = {}
      self.slaves.keys.each do |slave|
        begin
          retval[slave] = self.slaves[slave].send(method, *args)
        rescue ActiveResource::ResourceNotFound => e
          retval[slave] = self.slaves[slave].new
        end
      end
      retval
    end

    SATELLITE_LOCATIONS.keys.each do |location|
      base.add_slave(location, SATELLITE_LOCATIONS[location])
    end

    # Register the after_save handles
    base.after_save do |record|
      if base.update_satellites
        satellite_records = base.propogate_method(:find, record.id)
        satellite_records.each do |location,satellite_record|
          newr = satellite_record.new?
          satellite_record.attributes = record.public_attributes
          satellite_record.id = record.id
          if newr
            satellite_record.create
          else
            satellite_record.save
          end
        end
      else
        base.journal << {:save => record.public_attributes}
      end
    end
    base.before_destroy do |record|
      if base.update_satellites
        satellite_records = base.propogate_method(:find, record.id)
        satellite_records.each do |satellite_record|
          satellite_record.destroy
        end
      else
        base.journal << {:destroy => record.id}
      end
    end
    # * * * *
  end
end
