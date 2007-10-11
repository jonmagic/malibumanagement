require 'fileutils'

def with(*objects)
  yield(*objects)
  return *objects
end

class EftBatch < ActiveRecord::Base
  attr_accessor :members, :no_eft, :froze, :expired, :no_aba

  serialize :eft_count_by_location, Hash
  serialize :eft_count_by_amount, Hash
  serialize :eft_total_by_location, Hash

  def initialize(attrs={}) # 2007/11
    # EftBatch.new -- will gather information from Helios::ClientProfile and Helios::Eft.
    # Generate 3 CSV's from live data and save them in that month's directory.
    @members = []
    @no_eft = []
    @froze = []
    @expired = []
    @no_aba = []
    super(attrs)
    month = attrs['for_month'] if attrs.has_key?('for_month')
  # Sets to the next month after today's month. If today is December, it will roll over the year as well.
    month ||= (Time.now.strftime("%Y").to_i + Time.now.strftime("%m").to_i/12).to_i.to_s + '/' + Time.now.strftime("%m").to_i.cyclical_add(1, 1..12).to_s
    total_amount = 0
    locations_amounts = {}
    locations_count = {}
    amounts_count = {}
    sql = ''
    case ::RAILS_ENV
    when 'development'
      sql = "(Member1 = 'VIP' AND '"+Time.parse(month).strftime("%Y-%m-%d")+"' >= Member1_Beg AND Member1_Exp >= '"+Time.parse(month).strftime("%Y-%m-%d")+"') OR (Member2 = 'VIP' AND '"+Time.parse(month).strftime("%Y-%m-%d")+"' >= Member2_Beg AND Member2_Exp >= '"+Time.parse(month).strftime("%Y-%m-%d")+"')"
    when 'production'
      sql = "([Member1] = 'VIP' AND '"+Time.parse(month).strftime("%Y%m%d")+"' >= [Member1_Beg] AND [Member1_Exp] >= '"+Time.parse(month).strftime("%Y%m%d")+"') OR ([Member2] = 'VIP' AND '"+Time.parse(month).strftime("%Y%m%d")+"' >= [Member2_Beg] AND [Member2_Exp] >= '"+Time.parse(month).strftime("%Y%m%d")+"')"
    end

    Helios::ClientProfile.find(:all, :conditions => [sql]).each do |cp|
      if cp.eft.nil?
        @no_eft << cp.id.to_i
      else
        if(!((!cp.eft.Freeze_Start.nil? ? cp.eft.Freeze_Start.to_date <= Time.parse(month).to_date : false) && (!cp.eft.Freeze_End.nil? ? Time.parse(month).to_date <= cp.eft.Freeze_End.to_date : false)) && ((!cp.eft.Start_Date.nil? ? cp.eft.Start_Date.to_date <= Time.parse(month).to_date : true) && (!cp.eft.End_Date.nil? ? Time.parse(month).to_date <= cp.eft.End_Date.to_date : true)))
          if(false) # Check credit card expiration
            @expired << cp.id.to_i
          else
            @no_aba << cp.id.to_i if cp.eft.Bank_ABA.nil? && cp.eft.Acct_Exp.nil?
            @members << cp.id.to_i

            location_code = cp.eft.Location || '00'+cp.eft.Client_No.to_s[0,1]
            location_str = HELIOS_LOCATION_CODES[location_code] || location_code
            amount_int = (cp.eft.Monthly_Fee.to_f*100).to_i

            total_amount += amount_int

            locations_amounts[location_str] ||= 0
            locations_amounts[location_str] += amount_int

            locations_count[location_str] ||= 0
            locations_count[location_str] += 1

            amounts_count[amount_int] ||= 0
            amounts_count[amount_int] += 1
          end
        else
          @froze << cp.id.to_i
        end
      end
    end
    self.for_month = month
    self.eft_count = @members.length
    self.eft_total = total_amount
    # t.column :eft_count_by_location, :string, :default => {}.to_yaml
    self.eft_count_by_location = locations_count
    # t.column :eft_count_by_amount, :string, :default => {}.to_yaml
    self.eft_count_by_amount = amounts_count
    # t.column :eft_total_by_location, :string, :default => {}.to_yaml
    self.eft_total_by_location = locations_amounts
    # t.column :memberships_without_efts, :integer
    self.memberships_without_efts = @no_eft.length
    # t.column :members_with_expired_cards, :integer
    self.members_with_expired_cards = @expired.length

    path = 'EFT/'+self.for_month+'/' # should be different for each month and should end in /
    FileUtils.mkpath(path)
    with(File.open(path+'payment.csv', 'w')) do |file|
      @members.each do |m|
        file.write("#{m}\r\n")
      end
    end.close

    with(File.open(path+'no_eft.csv', 'w')) do |file|
      @no_eft.each do |n|
        file.write("#{n}\r\n")
      end
    end.close

    with(File.open(path+'expired.csv', 'w')) do |file|
      @expired.each do |n|
        file.write("#{n}\r\n")
      end
    end.close
  end

  def submit_for_payment!
    # Sends the generated payment CSV to the payment gateway
    self.update_attributes(:submitted_at => Now)
  end
end

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
