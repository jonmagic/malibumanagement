#!/usr/bin/env /Users/daniel/Sites/sixsigma/branches/malibu/script/runner

# The Process:
# Check the sftp site every hour for files from gotobilling, download them and process them as responses to GotoTransactions.

require 'rubygems'
require 'net/ssh'
require 'net/sftp'

host = 'sftp.malibutan.com' || 'sftp.malibu-tanning.com'
username = 'malibu2' || 'malibu'
password = 'gn1nn4t'
path = "/home/#{username}/gotobilling"
while sleep(3600) # Wait one hour between checks.
  files = []
  for_month = Time.now.strftime("%Y") + '/' + Time.now.strftime("%m")
  Net::SFTP.start(host, username, password) do |sftp|
    handle = sftp.opendir(path)
    items = sftp.readdir(handle)
    files = items.collect {|i| i.filename}.reject {|a| a !~ /\.csv$/}
    sftp.close_handle(handle)
    files.each do |file|
      puts "Downloading file #{file}..."
      sftp.remove(path+'/'+file) if sftp.get_file path+'/'+file, "EFT/"+for_month+'/'+file
    end
  end

  puts "Loading pending transactions..."
  pending = {}
  headers = true
  CSV::Reader.parse(File.open('EFT/'+for_month+'/payment.csv', 'rb')) do |row|
    if headers
      headers = false
      next
    end
    t = GotoTransaction.new_from_csv_row(row)
    pending[t.invoice_id] = t
  end
  puts "Processing responses..."
  files = Dir.open('EFT/'+for_month).collect.reject {|a| a !~ /returns.*\.csv$/}
  files.each do |file|
    headers = []
    CSV::Reader.parse(File.open("EFT/"+for_month+'/'+file, 'rb')) do |row|
      if headers.blank?
        headers = row
        next
      end
      response = {}
      headers.length.times do |i|
        response[headers[i]] = row[i]
      end
      t = pending[response['invoice_id']]
      t.instance_variable_set('@response', response)
      t.instance_variable_set('@new_record', false)
      # Now 't' is just as if we just now submitted the transaction and got a response back into it.

      # Accepted ACH: 
      # Accepted Credit: 
      # Declined ACH: 
      # Declined Credit: 
    end
  end
  puts "Saving results to batch..."
end

# transact_no   ?
# ticket_no   ?
# client_no   client.id
# Last_Name   client.FirstName
# First_Name    client.LastName
# Last_Mdt    Now
# Code      EFT Active
# Description   ?
# CType     ?
# Division    zone1: 2, zone2: 1
# Department    zone1: 7, zone2: 2
# Price     eft.price
# Check     if checking/savings   and cleared   then eft.price
# Charge      if creditcard     and cleared   then eft.price
# Credit      if check/savings/credit and NOTCLEARED  then eft.price
# Modified    if updating transaction then copy Last_Mdt to here and update Last_Mdt
