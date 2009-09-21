# Script: push_end_dates
# Purpose: Change all active EFT profiles with an End_Date >= 12/31/09 to 1/1/2020 and corresponding ClientProfile's Member1_Exp & Member2_Exp to 1/1/2020
# This file is to be run in the context of the application: To run, use ./script/runner

updated = Helios::Eft.memberships_between("2009/12/31", "2020/01/01") do |client|
  debug_step "Begin: '#{client.First_Name} #{client.Last_Name}' (M1:#{client.Member1}, M2:#{client.Member2} Exp:#{client.Member1_Exp}#{client.Member2_Exp}, EFT.End_Date:#{client.eft.End_Date})" if ARGV.include?('--debug-step')
  if(client.Member1 == 'VIP')
    client.update_attributes(
      :Member1_Exp => Time.gm('2020', '01', 1, 0, 0, 0),
      :UpdateAll => Time.now
    )
  elsif(client.Member2 == 'VIP')
    client.update_attributes(
      :Member2_Exp => Time.gm('2020', '01', 1, 0, 0, 0),
      :UpdateAll => Time.now
    )
  end
  client.eft.update_attributes(
    :End_Date => Time.gm('2020', '01', 1, 0, 0, 0),
    :UpdateAll => Time.now
  )
  debug_step "Continue?" if ARGV.include?('--debug-step')
end

puts "Done: #{updated.length} Updated."
