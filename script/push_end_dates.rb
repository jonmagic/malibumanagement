# Script: push_end_dates
# Purpose: Change all active EFT profiles with an End_Date >= 12/31/09 to 1/1/2020 and corresponding ClientProfile's Member1_Exp & Member2_Exp to 1/1/2020
# This file is to be run in the context of the application: To run, use ./script/runner

updated = Helios::Eft.memberships_between("2009/12/31", "2020/01/01") do |client|
  unless client.has_prepaid_membership?(Time.parse("2009/12/31"))
    confirm_step("Update '#{client.First_Name} #{client.Last_Name}' (M1:#{client.Member1}, M2:#{client.Member2} Exp:#{client.Member1_Exp}#{client.Member2_Exp}, EFT.End_Date:#{client.eft.End_Date})") do
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
