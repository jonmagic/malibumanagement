require 'fileutils'
require 'csv'

def with(*objects)
  yield  *objects
  return *objects
end

class EftBatch < ActiveRecord::Base
  attr_accessor :members, :missing_efts, :invalid_efts

  serialize :eft_count_by_location, Hash
  serialize :eft_count_by_amount, Hash
  serialize :eft_total_by_location, Hash

  def eft_path
    'EFT/'+self.for_month+'/'
  end

  def initialize(attrs={}) # 2007/11
    # EftBatch.new -- will gather information from Helios::ClientProfile and Helios::Eft.
    # Generate 3 CSV's from live data and save them in that month's directory.
    @members = []
    @missing_efts = []
    @invalid_efts = []
    @location_members = {}
    super(attrs)
    month = attrs['for_month'] if attrs.has_key?('for_month')
  # Sets to the next month after today's month. If today is December, it will roll over the year as well.
    month ||= (Time.now.strftime("%Y").to_i + Time.now.strftime("%m").to_i/12).to_i.to_s + '/' + Time.now.strftime("%m").to_i.cyclical_add(1, 1..12).to_s
    total_amount = 0
    locations_amounts = {}
    locations_count = {}
    amounts_count = {}

    Helios::Eft.memberships(month, true) do |cp|
      unless cp.has_prepaid_membership?
        if cp.eft.nil?
          @missing_efts << [cp.id.to_i]
        else
  # ActionController::Base.logger.info("ID #{cp.id.to_i}")
          t = GotoTransaction.new(cp.eft)
          if(!t.valid?)
            @invalid_efts << [cp.id.to_i,t.errors.full_messages.to_sentence]
          else
            location_code = cp.eft.Location || '0'*(3-ZONE_LOCATION_BITS)+cp.eft.Client_No.to_s[0,ZONE_LOCATION_BITS]
            location_str = LOCATIONS[location_code][:name]
            if(location_str.blank?)
              ActionController::Base.logger.info("EFT ##{cp.eft.id} has unknown location code of #{location_code}!")
              location_str = location_code
            end
            locations_amounts[location_code] ||= 0
            locations_count[location_code] ||= 0
            amounts_count[t.amount] ||= 0
            @location_members[location_code] ||= []

            # Should we be using cp.eft.Client_Name for the credit_card_name?
            @members << t.to_a
            @location_members[location_code] << [t.account_id, t.last_name, t.first_name]

            total_amount += t.amount
            locations_amounts[location_code] += t.amount
            locations_count[location_code] += 1
            amounts_count[t.amount] += 1
          end
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
      writer << ['AccountId', 'Location', 'MerchantId', 'FirstName', 'LastName', 'BankRoutingNumber', 'BankAccountNumber', 'NameOnCard', 'CreditCardNumber', 'Expiration', 'Amount', 'Type', 'AccountType', 'Authorization']
      @members.each {|m| writer << m}
    end
    @location_members.each do |loc_code,members|
      CSV.open(path+loc_code.to_s+'.csv', 'w') do |writer|
        writer << ['Client_No','LastName', 'FirstName']
        members.each {|m| writer << m}
      end
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
end
