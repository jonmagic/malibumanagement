require 'fileutils'

class EftBatch < ActiveRecord::Base
  has_many :payments, :class_name => 'GotoTransaction', :foreign_key => 'batch_id'

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

  def amounts_counts
    @amounts_counts ||= begin
      it = {}
      self.payments.connection.select_values('SELECT amount FROM goto_transactions GROUP BY amount').compact.each do |amount|
        it[amount] = self.payments.connection.select_value('SELECT COUNT(*) FROM goto_transactions WHERE amount="'+amount.to_s+'"').to_i
      end
      it
    end
  end

  def locations_counts
    @locations_counts ||= begin
      it = {}
      it['all'] ||= {}
      it['all'][:all] ||= 0
      it['all'][:valid] ||= 0
      it['all'][:no_eft] ||= 0
      it['all'][:invalid] ||= 0
      self.payments.each do |pm|
        it[pm.location] ||= {}
        it[pm.location][:all] ||= 0
        it[pm.location][:valid] ||= 0
        it[pm.location][:no_eft] ||= 0
        it[pm.location][:invalid] ||= 0

        it[pm.location][:all] += 1
        it[pm.location][:valid] += 1 if !pm.no_eft && pm.goto_invalid.to_s == ''
        it[pm.location][:no_eft] += 1 if pm.no_eft
        it[pm.location][:invalid] += 1 if pm.goto_invalid.to_s != ''
        it['all'][:all] += 1
        it['all'][:valid] += 1 if !pm.no_eft && pm.goto_invalid.to_s == ''
        it['all'][:no_eft] += 1 if pm.no_eft
        it['all'][:invalid] += 1 if pm.goto_invalid.to_s != ''
      end
      it
    end
  end

  # EftBatch.create(:for_month => '2007/12').generate -- will gather information from Helios::ClientProfile and Helios::Eft.
  def generate(for_location=nil,force=false)
    if new_record?
      return(false) unless save
    end
    return false if self.locked unless force
puts "Generating for #{Time.parse(for_month).month_name}#{" at location "+for_location if for_location}..."
timestart = Time.now
    if for_location.nil?
      self.no_eft_count  = 0
      self.invalid_count = 0
    end
    GotoTransaction.delete_all(['batch_id=?', self.id]) if for_location.nil? # Destroy all GotoTransactions, then recreate them. We won't allow generating after the batch has begun processing.
    Helios::Eft.memberships(for_month, true) do |cp|
      if for_location.nil?
        unless cp.has_prepaid_membership?
          t = GotoTransaction.new(self.id, cp)
          self.no_eft_count += 1 if cp.eft.nil?
          self.invalid_count += 1 if t.goto_is_invalid?
          t.save
        end
      else
        if !cp.eft.nil?
          the_location = cp.eft.Location || '0'*(3-ZONE[:Location_Bits])+cp.eft.Client_No.to_s[0,ZONE[:Location_Bits]]
          if for_location == the_location && !cp.has_prepaid_membership?
            t = GotoTransaction.new(self.id, cp.eft)
            t.save
          end
        end
      end
    end
    self.last_total_regenerate = Time.now if for_location.nil?
    self.regenerate_now = ''
    self.save
timeend = Time.now
puts "Generate Finished. Took #{timeend - timestart} seconds."
  end
end
