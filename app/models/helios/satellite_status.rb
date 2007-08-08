class Helios::SatelliteStatus < ActiveRecord::Base
  def write_attribute(att, value)
    super
    save
  end
end