# Script: fix_prepaid_end_dates
# Algorithm: Find all VY and VY+ transactions, and for those who have an EFT profile, fix their ClientProfile's Member#_Exp to the appropriate amount for their purchase (425 days for VY, 545 days for VY+), and fix their Eft's End_Date to the date they purchased the prepaid.
# This file is to be run in the context of the application: To run, use ./script/runner

sql = case ::RAILS_ENV
when 'development'
  old_date_s = "2008-07-04" # this is 545 days before 12/31/2009
  "(Code = 'V' OR Code = 'V199' OR Code = 'VX' OR Code = 'VY' OR Code = 'VY+' OR Code = 'V1M' OR Code = 'V1W') AND CType != ? AND CType != ? AND Last_Mdt > ?"
when 'production'
  old_date_s = "20080704" # this is 545 days before 12/31/2009
  "([Code] = 'V' OR [Code] = 'V199' OR [Code] = 'VX' OR [Code] = 'VY' OR [Code] = 'VY+' OR [Code] = 'V1M' OR [Code] = 'V1W') AND [CType] != ? AND [CType] != ? AND [Last_Mdt] > ?"
end

clients = Helios::Transact.find(:all, :conditions => [sql, '1', '2', old_date_s])

clients.each do |client|
  report = client.report_membership!
  if report =~ /prepaid/
    prepaid = report.instance_variable_get(:@prepaid)
    confirm_step "#{report}\nChange: #{client.Member1 == 'VIP' ? 'client.Member1_Exp' : 'client.Member2_Exp'}=#{prepaid.Last_Mdt}", '' do
      
    end
  end
end


# updated = Helios::Eft.memberships_between("2009/12/31", "2020/01/01") do |client|
#   # confirm_step "Begin: '#{client.First_Name} #{client.Last_Name}' (M1:#{client.Member1}, M2:#{client.Member2} Exp:#{client.Member1_Exp}#{client.Member2_Exp}, EFT.End_Date:#{client.eft.End_Date})" if ARGV.include?('--debug-step')
#   if(client.Member1 == 'VIP')
#     Helios::ClientProfile.connection.execute("UPDATE Client_Profile SET [Member1_Exp] = '20200101 00:00:00', [UpdateAll] = '#{Time.now.strftime("%Y%m%d %H:%M:%S")}' WHERE [Client_no] = '#{client.Client_no}'")
#   elsif(client.Member2 == 'VIP')
#     Helios::ClientProfile.connection.execute("UPDATE Client_Profile SET [Member2_Exp] = '20200101 00:00:00', [UpdateAll] = '#{Time.now.strftime("%Y%m%d %H:%M:%S")}' WHERE [Client_no] = '#{client.Client_no}'")
#   end
#   client.eft.update_attributes(
#     :End_Date => Time.parse("2020/01/01"),
#     :UpdateAll => Time.now
#   )
#   debug_step "Continue?" if ARGV.include?('--debug-step')
# end

puts "Done: #{count_updated} Updated, #{count_skipped} Skipped."
