class HeliosController < ApplicationController
  layout 'admin'

  def index # Show the page of available functions
    restrict('allow only admins')
  end

  def satellite_status
    restrict('allow only admins') or begin
      respond_to do |format|
        format.xml {
          render :xml => {:text => Thread.current['satellite_status'].status_text || '', :percent => Thread.current['satellite_status'].percent || 100}.to_xml(:root => :status)
        }
      end
    end
  end

  def fixmismatch
    restrict('allow only admins') or begin
      count = Helios::ClientProfile.fixmismatch
      @locations = {}
      @locations['Central'] = {'success' => true, 'count' => count}
      last_location_done = nil
      open_helios_locations = LOCATIONS.reject {|k,v| !v.has_key?(:open_helios) }
      open_helios_locations.each do |location,site|
        # Thread.current['satellite_status'].status_text = (last_location_done ? (!last_location_done.has_key?('error') ? "#{last_location_done['count']} fixed at #{last_location_done['location']}. " : "#{result['error']} at #{last_location_done['location']}. ") : '') + "Fixing errors at #{location}..."
        # Thread.current['satellite_status'].percent = 100 / (@locations.keys.length) * (open_helios_locations.keys.length+2)
        begin
          conn = ActiveResource::Connection.new("http://#{site}")
          resp = conn.put('/fixmismatch')
        rescue Errno::ETIMEDOUT => e
          err = "Connection Failed"
        rescue Timeout::Error => e
          err = "Connection Failed"
        rescue Errno::EHOSTDOWN => e
          err = "Connection Failed"
        ensure
          if err
            @locations[location] = {'success' => false, 'count' => 0, 'error' => err}
          else
            @locations[location] = conn.xml_from_response(resp)
          end
          last_location_done = @locations[location].merge('location' => location)
        end
      end
      # Thread.current['satellite_status'].status_text = (last_location_done ? (!last_location_done.has_key?('error') ? "#{last_location_done['count']} fixed at #{last_location_done['location']}. " : "#{result['error']} at #{last_location_done['location']}. ") : '')
      # Thread.current['satellite_status'].percent = 100
      render :layout => false
    end
  end
end
