require 'fileutils'

class Fixnum
  # Adds one number to another, but rolls over to the beginning of the range whenever it hits the top of the range.
  def cyclical_add(addend, cycle_range)
    raise ArgumentError, "#{self} is not within range #{cycle_range}!" if !cycle_range.include?(self)
    while(self+addend > cycle_range.last)
      addend -= cycle_range.last-cycle_range.first+1
    end
    return self+addend
  end
end

def with(*objects)
  yield  *objects
  return *objects
end

class EftBatch < ActiveRecord::Base
  def initialize(attrs={})
    super
    # Auto-sets to the next month after today's month. If today is December, it will roll over the year as well.
    self.for_month ||= (Time.now.strftime("%Y").to_i + Time.now.strftime("%m").to_i/12).to_i.to_s + '/' + Time.now.strftime("%m").to_i.cyclical_add(1, 1..12).to_s
    # Pretend we're the already-made batch if one for this month already exists
    if exis = self.class.find_by_for_month(self.for_month)
      self.attributes = exis.attributes
      self.id = exis.id
      @new_record = false
    end
    self.no_eft_count ||= 0
    self.invalid_count ||= 0
  end

  def self.create(*args)
    b = new(*args)
    b.save
    b
  end

  def for_month=(v)
    write_attribute(:for_month, Time.parse(v.to_s).strftime("%Y/%m"))
  end

  # EftBatch.create(:for_month => '2007/12').generate -- will gather information from Helios::ClientProfile and Helios::Eft.
  def generate(for_location=nil)
    if new_record?
      return(false) unless save
    end
puts "Generating for #{Time.parse(for_month).month_name}..."
    timestart = Time.now
    Helios::Eft.memberships(for_month, true) do |cp|
      if for_location.nil?
        unless cp.has_prepaid_membership?
          t = GotoTransaction.new(cp.eft)
          t.batch = self
          if cp.eft.nil?
            t.no_eft = true
            self.no_eft_count += 1
          else
            t.location = cp.eft.Location || '0'*(3-ZONE_LOCATION_BITS)+cp.eft.Client_No.to_s[0,ZONE_LOCATION_BITS]
            self.invalid_count += 1 if t.goto_is_invalid?
          end
          t.save
        end
      else
        if !cp.eft.nil?
          the_location = cp.eft.Location || '0'*(3-ZONE_LOCATION_BITS)+cp.eft.Client_No.to_s[0,ZONE_LOCATION_BITS]
          if for_location == the_location && !cp.has_prepaid_membership?
            t = GotoTransaction.new(cp.eft)
            t.batch = self
            t.location = the_location
            t.save
          end
        end
      end
    end
    self.save
    timeend = Time.now
puts "Generate Finished. Took #{timeend - timestart} seconds."
  end
end
