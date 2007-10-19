require 'optiflag'
module Payment extend OptiFlag::FlagsetDefinitions
  flag "csv"
end 
cl = Payment::parse(ARGV)
if cl.errors?
  cl.errors.divulge_problems
  exit
end
@CSV = cl.flag_value.csv

require 'gotobilling/lib/gotobilling.rb'
require 'gotobilling/lib/transactions.rb'

# 1) Read the CSV.
# 2) Each line, create a new Transaction & submit it; act on the result.
# 3) Generate an immediate_return.csv to place next to the @CSV.
