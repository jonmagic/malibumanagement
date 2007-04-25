class InventoryList < ActiveRecord::Base
  # ('second_db' is defined in database.yaml)
  establish_connection :odbc_inventory

   def self.auth_user(member_no)
      return find(:first,:conditions => ["member_no = ?",member_no])
   end
end
