#Commented out are for fenestra, uncommented are for malibu

class FixSomeColumns < ActiveRecord::Migration
  def self.up
    rename_column :direct_deposit_authorizations, :account_type, :account_kind
    # remove_column :direct_deposit_authorizations, :authorization_new_updated
    # remove_column :performance_reviews, :manager_sign_id
    # remove_column :performance_reviews, :manager_sign_hash
    # remove_column :performance_reviews, :manager_sign_date
    # remove_column :performance_reviews, :employee_sign_id
    # remove_column :performance_reviews, :employee_sign_hash
    # remove_column :performance_reviews, :employee_sign_date
    # remove_column :time_off_requests, :employee_signature_id
    # remove_column :time_off_requests, :employee_signature_hash
    # remove_column :time_off_requests, :employee_signature_date
    # remove_column :time_off_requests, :admin_review_id
    # remove_column :time_off_requests, :admin_review_hash
    # remove_column :time_off_requests, :admin_review_date
    # remove_column :time_off_requests, :admin_approval_id
    # remove_column :time_off_requests, :admin_approval_hash
    # remove_column :time_off_requests, :admin_approval_date
  end

  def self.down
  end
end
