class EftBatch < ActiveRecord::Base
  attr_accessor :members, :no_eft, :froze, :expired

  def initialize(attrs={}) # 2007/11
    # EftBatch.new -- will gather information from Helios::ClientProfile and Helios::Eft.
    # Generate 3 CSV's from live data and save them in that month's directory.
    @members = []
    @no_eft = []
    @froze = []
    @expired = []
    super(attrs)
    month = attrs[:month] if attrs.has_key?(:month)
    month ||= '2007/11'
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

    Helios::ClientProfile.find(:all, :conditions => [sql], :limit => 120).each do |cp|
      if cp.eft.nil?
        @no_eft << cp.id.to_i
      else
        if(!((!cp.eft.Freeze_Start.nil? ? cp.eft.Freeze_Start.to_date <= Time.parse(month).to_date : false) && (!cp.eft.Freeze_End.nil? ? Time.parse(month).to_date <= cp.eft.Freeze_End.to_date : false)) && ((!cp.eft.Start_Date.nil? ? cp.eft.Start_Date.to_date <= Time.parse(month).to_date : true) && (!cp.eft.End_Date.nil? ? Time.parse(month).to_date <= cp.eft.End_Date.to_date : true)))
          if(false) # Check credit card expiration
            @expired << cp.id.to_i
          else
            @members << cp.id.to_i

            total_amount += (cp.eft.Monthly_Fee.to_f*100).to_i

            locations_amounts[HELIOS_LOCATION_CODES[cp.eft.Location]] ||= 0
            locations_amounts[HELIOS_LOCATION_CODES[cp.eft.Location]] += (cp.eft.Monthly_Fee.to_f*100).to_i

            locations_count[HELIOS_LOCATION_CODES[cp.eft.Location]] ||= 0
            locations_count[HELIOS_LOCATION_CODES[cp.eft.Location]] += 1

            amounts_count[(cp.eft.Monthly_Fee.to_f*100).to_i] ||= 0
            amounts_count[(cp.eft.Monthly_Fee.to_f*100).to_i] += 1
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
  end

  def submit_for_payment!
    # Sends the generated payment CSV to the payment gateway
    self.update_attributes(:submitted_at => Now)
  end
end
