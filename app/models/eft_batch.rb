require 'fileutils'

def with(*objects)
  yield(*objects)
  return *objects
end

class EftBatch < ActiveRecord::Base
  attr_accessor :members, :missing_efts, :invalid_efts

  serialize :eft_count_by_location, Hash
  serialize :eft_count_by_amount, Hash
  serialize :eft_total_by_location, Hash

  def initialize(attrs={}) # 2007/11
    require 'csv'
    # EftBatch.new -- will gather information from Helios::ClientProfile and Helios::Eft.
    # Generate 3 CSV's from live data and save them in that month's directory.
    @members = []
    @missing_efts = []
    @invalid_efts = []
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
        @missing_efts << [cp.id.to_i]
      else
        if(!((!cp.eft.Freeze_Start.nil? ? cp.eft.Freeze_Start.to_date <= Time.parse(month).to_date : false) && (!cp.eft.Freeze_End.nil? ? Time.parse(month).to_date <= cp.eft.Freeze_End.to_date : false)) && ((!cp.eft.Start_Date.nil? ? cp.eft.Start_Date.to_date <= Time.parse(month).to_date : true) && (!cp.eft.End_Date.nil? ? Time.parse(month).to_date <= cp.eft.End_Date.to_date : true)))
          if(cp.eft.Acct_Exp.nil? ? false : Time.parse(cp.eft.Acct_Exp.sub(/\//, '/01/')) < (Time.now+1.day).beginning_of_day) # Check credit card expiration .. does it expire before tomorrow?
            @invalid_efts << [cp.id.to_i,'Expired Card']
          else
            if cp.eft.Acct_Exp.blank? && cp.eft.Bank_ABA.blank?
              @invalid_efts << [cp.id.to_i,'No Routing Number']
            elsif cp.eft.Acct_Exp.blank? && !cp.eft.Bank_ABA.blank? && !validABA?(cp.eft.Bank_ABA)
              @invalid_efts << [cp.id.to_i,'Invalid Routing Number']
            elsif cp.eft.Acct_No.blank?
              @invalid_efts << [cp.id.to_i,'No '+(cp.eft.credit_card? ? 'Credit Card' : 'Bank Account')+' Number']
            elsif cp.eft.credit_card? && !cp.eft.Acct_No.blank? && !validCreditCardNumber?(cp.eft.Acct_No)
              @invalid_efts << [cp.id.to_i,'Invalid Credit Card Number']
            else
              # ['AccountID', 'FirstName', 'LastName', 'BankName', 'BankRoutingNumber', 'BankAccountNumber', 'NameOnCard', 'CreditCardNumber', 'Expiration', 'Amount', 'Type', 'AccountType, 'Authorization']
              location_code = cp.eft.Location || '00'+cp.eft.Client_No.to_s[0,1]
              location_str = HELIOS_LOCATION_CODES[location_code] || location_code
              amount_int = (cp.eft.Monthly_Fee.to_f*100).to_i

# Acct_Type
# A => American Express
# C => Checking
# I => Discover
# M => Mastercard
# S => Savings
# V => Visa

# total == 9315
# A == exp:70,   noexp:0,    aba:0 (70)
# C == exp:28,   noexp:3274, aba:3267 (35)
# I == exp:162,  noexp:0,    aba:7 (155)
# M == exp:2192, noexp:0,    aba:31 (2161)
# S == exp:5,    noexp:997,  aba:965 (37)
# V == exp:2586, noexp:0,    aba:17 (2569)

# Should we be using cp.eft.Client_Name for the credit_card_name?
              @members << [
                cp.id.to_i, # AccountID
                cp.eft.First_Name, # FirstName
                cp.eft.Last_Name, # LastName
                cp.eft.Bank_Name, # BankName
                cp.eft.Bank_ABA, # BankRoutingNumber
                cp.eft.credit_card? ? nil : cp.eft.Acct_No, # BankAccountNumber
                cp.eft.First_Name.to_s + ' ' + cp.eft.Last_Name.to_s, # NameOnCard
                cp.eft.credit_card? ? cp.eft.Acct_No : nil, # CreditCardNumber
                cp.eft.Acct_Exp.to_s.gsub(/\d/,''), # Expiration MMYY
                cp.eft.Monthly_Fee.to_f, # Amount
                cp.eft.credit_card? ? 'Credit Card' : 'ACH', # Type
                cp.eft.Acct_Type,
                'Written' # Authorization
              ]
              total_amount += amount_int

              locations_amounts[location_str] ||= 0
              locations_amounts[location_str] += amount_int

              locations_count[location_str] ||= 0
              locations_count[location_str] += 1

              amounts_count[amount_int] ||= 0
              amounts_count[amount_int] += 1
            end
          end
        else
          # @froze << cp.id.to_i
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
    self.memberships_without_efts = @missing_efts.length
    # t.column :members_with_expired_cards, :integer
    self.members_with_invalid_efts = @invalid_efts.length

    path = 'EFT/'+self.for_month+'/' # should be different for each month and should end in /
    FileUtils.mkpath(path)
    CSV.open(path+'payment.csv', 'w') do |writer|
      writer << ['AccountID', 'FirstName', 'LastName', 'BankName', 'BankRoutingNumber', 'BankAccountNumber', 'NameOnCard', 'CreditCardNumber', 'Expiration', 'Amount', 'Type', 'AccountType', 'Authorization']
      @members.each {|m| writer << m}
    end
    CSV.open(path+'missing_efts.csv', 'w') do |writer|
      writer << ['Client_No']
      @missing_efts.each {|m| writer << m}
    end
    CSV.open(path+'invalid_efts.csv', 'w') do |writer|
      writer << ['Client_No','Reason']
      @invalid_efts.each {|m| writer << m}
    end
  end

  def submit_for_payment!
    # Sends the generated payment CSV to the payment gateway
    self.update_attributes(:submitted_at => Now)
  end

  private
    def validABA?(aba)
      # 1) Check for all-numbers.
      # 2) Check length == 9
      # 3) Total of all digits (each multiplied by 3, 7 or 1 in cycle) should % 10
      i = 2
      aba.to_s.gsub(/\D/,'').length == 9 && aba.to_s.gsub(/\D/,'').split('').map {|d| d.to_i*[3,7,1][i=i.cyclical_add(1,0..2)] }.sum % 10 == 0
    end
    def validCreditCardNumber?(ccn)
  # 1) MOD 10 check
      odd = true
      ccn.to_s.gsub(/\D/,'').reverse.split('').map(&:to_i).collect { |d|
        d *= 2 if odd = !odd
        d > 9 ? d - 9 : d
      }.sum % 10 == 0 &&

  # 2) Card Prefix Check -X- We don't store the credit card type, so we can't perform this check.
      true &&

  # 3) Card Length Check -X- We don't store the credit card type, so we can't perform this check.
      true
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
