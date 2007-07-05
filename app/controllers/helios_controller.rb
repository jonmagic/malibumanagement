class HeliosController < ApplicationController
  layout 'admin'

  def index # Show the page of available functions
  end

  def FixMismatch13
    Helios::ClientProfile.update_satellites = true # Ensures satellite databases are updated automatically.
    Helios::ClientProfile.find_all_by_Member1(nil).each {|faulty| faulty.update_attributes(:Member1 => 0)}
    Helios::ClientProfile.find_all_by_Member2(nil).each {|faulty| faulty.update_attributes(:Member2 => 0)}
  end
end