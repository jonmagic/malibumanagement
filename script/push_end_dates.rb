# Script: push_end_dates
# Purpose: Change all active EFT profiles with an End_Date >= 12/31/09 to 1/1/2020 and corresponding ClientProfile's Member1_Exp & Member2_Exp to 1/1/2020
# This file is to be run in the context of the application: To run, use ./script/runner

updated = Helios::Eft.memberships_between("2009/12/31", "2020/01/01") do |client|
  report = client.report_membership!(Time.parse("2009-12-31"))
  if report =~ /prepaid/
    puts "Skipped prepaid member #{client.Client_no}"
  else
    confirm_step("#{client.Client_no}: #{report}\n#{client.Member1 == 'VIP' ? 'client.Member1_Exp' : 'client.Member2_Exp'},EFT.End_Date='2020-01-01' (was:#{client.Member1_Exp}#{client.Member2_Exp}, eft:#{client.eft.End_Date}))") do
      if(client.Member1 == 'VIP')
        Helios::ClientProfile.connection.execute("UPDATE Client_Profile SET [Member1_Exp] = '20200101 00:00:00', [UpdateAll] = '#{Time.now.strftime("%Y%m%d %H:%M:%S")}' WHERE [Client_no] = '#{client.Client_no}'")
      elsif(client.Member2 == 'VIP')
        Helios::ClientProfile.connection.execute("UPDATE Client_Profile SET [Member2_Exp] = '20200101 00:00:00', [UpdateAll] = '#{Time.now.strftime("%Y%m%d %H:%M:%S")}' WHERE [Client_no] = '#{client.Client_no}'")
      end
      client.eft.update_attributes(
        :End_Date => Time.parse("2020/01/01"),
        :UpdateAll => Time.now
      )
    end
  end
end

puts "Done: #{updated.length} Updated."
