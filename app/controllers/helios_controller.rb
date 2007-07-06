class HeliosController < ApplicationController
  layout 'admin'

  def index # Show the page of available functions
  end

  def FixMismatch13
    Helios::ClientProfile.update_satellites = true # Ensures satellite databases are updated automatically.
    Helios::ClientProfile.find_all_by_member1_flex(nil).each {|faulty| faulty.update_attributes(:member1_flex => 0)}
    Helios::ClientProfile.find_all_by_member2_flex(nil).each {|faulty| faulty.update_attributes(:member2_flex => 0)}
  end
end