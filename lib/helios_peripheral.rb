#Hmmm.. I *could* extend the hosting model to record its actions and then a function here could 'catch up' on all the satellite locations when instructed. 

# Ok, now I realize I NEED to make this actually rewrite the #destroy method: Destroy from each of the stores first, verifying they are gone, and then destroy own record ONLY IF all stores destroyed successfully. Record in object's #errors if not successful, and return appropriate error message to operator.

module HeliosPeripheral
  def self.included(base)
    base.extend ClassMethods
    # base.alias :old_destroy :destroy
    base.send(:include, InstanceMethods)
    base.cattr_accessor :update_satellites
    base.update_satellites = false
    base.cattr_accessor :slaves
    base.slaves = {}
    base.cattr_accessor :journal
    base.journal = []

    SATELLITE_LOCATIONS.keys.each do |location|
      base.add_slave(location, SATELLITE_LOCATIONS[location])
    end

    # Register the after_save handle
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

#     base.before_destroy do |record|
#       if base.update_satellites
#         satellite_records = base.propogate_method(:find, record.id)
#         satellite_records.each do |location, satellite_record|
# puts "Satellite #{location}: #{satellite_record.inspect}"
#           satellite_record.destroy
#         end
#       else
#         base.journal << {:destroy => record.id}
#       end
#     end
    # * * * *
  end

  module ClassMethods
    def add_slave(location_name, uri_base)
      self.slaves ||= {}
      self.slaves[location_name] = Class.new(ActiveResource::Base)
      self.slaves[location_name].site = "http://#{uri_base}/"
ActionController::Base.logger.info "Primary Key: #{self.primary_key}"
      self.slaves[location_name].primary_key = self.primary_key
      self.slaves[location_name].element_name = self.name.split("::").last.underscore
    end

    def propogate_method(method, *args)
      retval = {}
      self.slaves.keys.each do |slave|
        begin
puts "Finding #{args.inspect} at #{slave}"
ActionController::Base.logger.info "Performing #{method} for #{args.join(', ')} at #{slave}..."
          if Thread.current['satellite_status'].class.name == 'Helios::SatelliteStatus'
            Thread.current['satellite_status'].status_text = "Performing #{method} for #{args.join(', ')} at #{slave}..."
            Thread.current['satellite_status'].percent = 100 / (self.slaves.keys.index(slave)+1) * self.slaves.keys.length
          end
          retval[slave] = self.slaves[slave].send(method, *args)
        rescue ActiveResource::ResourceNotFound => e
        rescue Errno::ETIMEDOUT => e
          err = "Connection Failed"
        rescue Timeout::Error => e
          err = "Connection Failed"
        rescue Errno::EHOSTDOWN => e
          err = "Connection Failed"
        rescue ActiveResource::ConnectionError => e
          err = "Connection Failed"
        rescue ActiveResource::ClientError => e
          err = "Unknown Client Error"
        ensure
          if err
            ActionController::Base.logger.info "Error: #{err}"
            retval[slave] = self.slaves[slave].new
            retval[slave].errors.add_to_base(err)
          end
        end
ActionController::Base.logger.info "\tResult: #{retval[slave].inspect}"
      end
      retval
    end
  end

  module InstanceMethods
    def included(base)
      base.send(:alias, :old_destroy, :destroy)
    end
    # Tainted destroy for satellites also.
    #  1) Finds the record at all satellite locations
    #  2) Tries to delete all records that reported existing
    #  3) Deletes the central record IF all records' deletion was successful
    def destroy
puts "Using the tainted destroy method!"
      if self.class.update_satellites == true
ActionController::Base.logger.info "Updating satellites..."
puts "Finding satellites..."
        satellite_records = self.class.propogate_method(:find, self.id)
puts "Updating satellites..."
        satellite_records.each do |location, satellite_record|
ActionController::Base.logger.info("\tSatellite: #{location} -- #{satellite_record.inspect}")
puts "\tSatellite: #{location} -- #{satellite_record.inspect}"
          self.errors.add_to_base(satellite_record.errors.full_messages.to_sentence) if satellite_record.errors
          self.errors.add_to_base(satellite_record.errors.full_messages.to_sentence) if !satellite_record.errors.full_messages.blank?
ActionController::Base.logger.info("\t\tSkipping (doesn't exist at #{location})") if satellite_record.new?
puts "\t\tSkipping (doesn't exist at #{location})" if satellite_record.new?
          next if satellite_record.new?
          begin
ActionController::Base.logger.info("\t\tDestroying at #{location}...")
puts "\t\tDestroying at #{location}..."
            retval = satellite_record.destroy
ActionController::Base.logger.info("\t\tResult: #{retval.inspect}")
puts "\t\tResult: #{retval.inspect}"
            self.errors.add_to_base("Error destroying #{satellite_record}: #{retval}") unless retval
puts "(Recording error) Error destroying #{satellite_record}: #{retval}" unless retval
  # Need more rescue codes here
          rescue ActiveResource::ResourceNotFound => e
            # Somehow got destroy'd between finding it a second ago and trying to delete it now.
            # It's okay if it doesn't exist.
            # self.errors.add_to_base("Could not destroy from #{location}: does not exist!")
            err = "Record doesn't exist."
          rescue ActiveResource::ClientError => e
            err = "Could not destroy from #{location}: unknown error"
          rescue Errno::EHOSTDOWN => e
            err = "Failed to connect to #{location}: #{e.to_s}"
          rescue Errno::ETIMEDOUT => e
            err = "Failed to connect to #{location}: #{e.to_s}"
          rescue Timeout::Error => e
            err = "Failed to connect to #{location}: #{e.to_s}"
          rescue ActiveResource::ConnectionError => e
            err = "Failed to connect to #{location}: #{e.to_s}"
          ensure
            if err
ActionController::Base.logger.info("\t\tError! => #{err}")
puts "\t\t(Recording error) Error! => #{err}"
              self.errors.add_to_base(err)
            end
          end
        end
      end
      if self.errors.full_messages.blank?
        # THE ORIGINAL DELETE METHOD
        unless new_record?
puts "!! Deleting immediate record !"
          connection.delete <<-end_sql, "#{self.class.name} Destroy"
            DELETE FROM #{self.class.table_name}
            WHERE #{self.class.primary_key} = #{quoted_id}
          end_sql
        end

        freeze
        # * * * *
      end
      return self
    end
  end
end
