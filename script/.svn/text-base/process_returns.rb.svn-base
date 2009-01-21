require 'rubygems'
require 'fileutils'

def report(txt)
  begin
    puts(("  "*CoresExtensions::StepLevel[0]) + ">" + txt)
    ActionController::Base.logger.info("  "*CoresExtensions::StepLevel[0] + ">" + txt)
  rescue => e
    puts e
  end
end

# Process:
# 1) Shuffle through Invalids and create transactions & notes for them.
# 2) Check for files from gotobilling & download them.
# 3) Read responses into mysql.
@batch = EftBatch.find(:first, :conditions => ['locked=1'], :order => 'for_month DESC')

report "Running Process_Returns for #{@batch.for_month}"

step("Recording all completed transactions to Helios") do
  debug_step "Continue?" if ARGV.include?('--debug-step')
  # Find only those that have a status or are invalid
  trans = GotoTransaction.find(:all, :conditions => ['batch_id=? AND ((goto_invalid IS NOT NULL AND !(goto_invalid LIKE ?)) OR (status IS NOT NULL AND status != ?))', @batch.id, '%'+[].to_yaml+'%', ''], :order => 'id ASC')
  report "There are #{trans.length} completed transactions to record to Helios."
  # Filter to those that don't have a transaction_id
  to_record = trans.reject {|t| !t.transaction_id.blank? && t.transaction_id != 0}
  # FOR TESTING PURPOSES! (also tested on 20000002)
  # to_record = to_record[0..19]
  # * * * *
  report "Of these, #{to_record.length} have yet to be recorded to Helios."
  debug_step "Continue?" if ARGV.include?('--debug-step')

  counts = {:accepted => 0, :declined => 0, :invalid => 0}
  trans.each do |tran|
    step("Client ##{tran.client_id}") do
      stat_type = !tran.cached_valid? ? :invalid : (tran.status == 'G' ? :accepted : :declined)
      # Helios Categories:
      #   Paid
      #   Declined
      #   Informational
      #   Invalid
      helios_category = case
      when tran.accepted?
        'processing'
      when tran.paid?
        'paid'
      when tran.declined?
        'declined'
      when tran.cached_invalid?
        'invalid'
      when tran.informational?
        'informational'
      else
        'random_other_status'
      end + tran.ach?.to_s
      debug_step "#{tran.inspect} Continue?", helios_category if ARGV.include?('--debug-step')
      counts[stat_type] += 1
      # The payment could be accepted, declined, or invalid.
      tran.record_to_helios!
    end
  end
  report "#{counts[:accepted]} Accepted, #{counts[:declined]} Declined, #{counts[:invalid]} Invalid"
end unless ARGV.include?('--revert-helios')

step("Reverting everything recorded to Helios") do
  debug_step "Continue?" if ARGV.include?('--debug-step')
  # Find only those that have a status or are invalid
  trans = GotoTransaction.find(:all, :conditions => ['batch_id=? AND ((goto_invalid IS NOT NULL AND !(goto_invalid LIKE ?)) OR (status IS NOT NULL AND status != ?))', @batch.id, '%'+[].to_yaml+'%', ''], :order => 'id ASC')
  report "There are #{trans.length} completed transactions to revert in Helios."
  # Filter to those that don't have a transaction_id
  # to_record = trans.reject {|t| !t.transaction_id.blank? && t.transaction_id != 0}
  # FOR TESTING PURPOSES! (also tested on 20000002)
  # to_record = to_record[0..19]
  # * * * *
  # report "Of these, #{trans.length} have yet to be recorded to Helios."
  counts = {:accepted => 0, :declined => 0, :invalid => 0}
  trans.each do |tran|
    step("Client ##{tran.client_id}") do
      debug_step "#{tran.inspect} Continue?" if ARGV.include?('--debug-step')
      if tran.cached_valid? # Don't revert invalids until the revert_helios_client_profile! method is written and tested!
        counts[!tran.cached_valid? ? :invalid : (tran.status == 'G' ? :accepted : :declined)] += 1
        # The payment could be accepted, declined, or invalid.
        to_be_reverted = []
        to_be_reverted << 'Transaction' if !tran.transaction_id.blank? && tran.transaction_id != 0
        to_be_reverted << 'Note' if !tran.note_id.blank? && tran.note_id != 0
        to_be_reverted << 'Client Profile' if !tran.previous_balance.blank? || !tran.previous_payment_amount.blank?
        report "To be reverted: #{to_be_reverted.join(', ')}" if to_be_reverted.length > 1
        tran.revert_helios_transaction!
        # tran.revert_helios!
      end
    end
  end
  report "#{counts[:accepted]} Accepted, #{counts[:declined]} Declined, #{counts[:invalid]} Invalid"
end if ARGV.include?('--revert-helios')
