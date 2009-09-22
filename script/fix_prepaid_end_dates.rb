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

count_updated = 0
count_skipped = 0

clients.each do |client|
  confirm_step "Begin next client? (#{client.Client_no})", 'begin-next' do
    report = client.report_membership!
    if report =~ /prepaid/
      prepaid = report.instance_variable_get(:@prepaid)
      eft = report.instance_variable_get(:@eft)
      vip_expire_date = prepaid.Last_Mdt + ((prepaid.Code == 'VY' ? 425 : 545) * 24*60*60).to_date.to_time # number of days following.
      msg = "\n#{report}\nChange: #{client.Member1 == 'VIP' ? 'client.Member1_Exp' : 'client.Member2_Exp'}=#{vip_expire_date.strftime("%Y-%m-%d")}"
      msg << ", EFT.End_Date=#{prepaid.Last_Mdt.to_time.strftime("%Y-%m-%d")}" if eft
      count_skipped += 1
      confirm_step msg, 'fix-end-date' do
        count_skipped -= 1
        count_updated += 1
        if(client.Member1 == 'VIP')
          Helios::ClientProfile.connection.execute("UPDATE Client_Profile SET [Member1_Exp] = '#{vip_expire_date.strftime("%Y-%m-%d %H:%M:%S")}', [UpdateAll] = '#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}' WHERE [Client_no] = '#{client.Client_no}'")
        elsif(client.Member2 == 'VIP')
          Helios::ClientProfile.connection.execute("UPDATE Client_Profile SET [Member2_Exp] = '#{vip_expire_date.strftime("%Y%m%d %H:%M:%S")}', [UpdateAll] = '#{Time.now.strftime("%Y%m%d %H:%M:%S")}' WHERE [Client_no] = '#{client.Client_no}'")
        end
        client.eft.update_attributes(
          :End_Date => prepaid.Last_Mdt.to_time,
          :UpdateAll => Time.now
        ) if eft
      end
    end
  end
end

puts "Done: #{count_updated} Updated, #{count_skipped} Skipped."
