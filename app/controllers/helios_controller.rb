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
      count = 0
      Helios::ClientProfile.update_satellites = false # Ensures satellite databases are NOT updated automatically.
      Helios::ClientProfile.find_all_by_member1_flex(nil).each {|faulty| count += 1 if faulty.update_attributes(:member1_flex => 0) }
      Helios::ClientProfile.find_all_by_member2_flex(nil).each {|faulty| count += 1 if faulty.update_attributes(:member2_flex => 0) }
      @locations = {}
      @locations['Central'] = {'success' => true, 'count' => count}
      last_location_done = nil
      SATELLITE_LOCATIONS.each do |location,site|
        Thread.current['satellite_status'].status_text = (last_location_done ? (!last_location_done.has_key?('error') ? "#{last_location_done['count']} fixed at #{last_location_done['location']}. " : "#{result['error']} at #{last_location_done['location']}. ") : '') + "Fixing errors at #{location}..."
        Thread.current['satellite_status'].percent = 100 / (@locations.keys.length) * (SATELLITE_LOCATIONS.keys.length+2)
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
      Thread.current['satellite_status'].status_text = (last_location_done ? (!last_location_done.has_key?('error') ? "#{last_location_done['count']} fixed at #{last_location_done['location']}. " : "#{result['error']} at #{last_location_done['location']}. ") : '')
      Thread.current['satellite_status'].percent = 100
      render :layout => false
    end
  end
end