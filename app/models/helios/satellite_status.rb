class Helios::SatelliteStatus < ActiveRecord::Base
  def write_attribute(att, value)
    super
    save unless new_record? # Very important, otherwise this goes into an infinite loop when creating new records!
  end
end