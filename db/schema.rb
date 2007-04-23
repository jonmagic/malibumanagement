# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 15) do

  create_table "account_setups", :force => true do |t|
  end

  create_table "admins", :force => true do |t|
    t.column "username",               :string
    t.column "friendly_name",          :string,   :limit => 50
    t.column "crypted_password",       :string,   :limit => 40
    t.column "salt",                   :string,   :limit => 40
    t.column "created_at",             :datetime
    t.column "updated_at",             :datetime
    t.column "activated_at",           :datetime
    t.column "social_security_number", :integer,  :limit => 9
  end

  create_table "direct_deposit_authorizations", :force => true do |t|
    t.column "employee_name",             :string
    t.column "employee_id_number",        :integer
    t.column "depository_bank",           :string
    t.column "bank_city",                 :string
    t.column "bank_branch",               :string
    t.column "bank_routing_number",       :integer
    t.column "bank_account_number",       :integer
    t.column "account_kind",              :string
    t.column "amount",                    :decimal, :precision => 8, :scale => 2
    t.column "effective_date",            :date
    t.column "date_received",             :date
    t.column "date_pre_note_sent",        :date
    t.column "date_of_first_payroll",     :date
    t.column "authorization_new_updated", :string
  end

  create_table "form_instances", :force => true do |t|
    t.column "form_type_id",       :integer
    t.column "store_id",           :integer
    t.column "customer_id",        :integer
    t.column "user_id",            :integer
    t.column "data_id",            :integer
    t.column "data_type",          :string
    t.column "status_number",      :integer,  :default => 1
    t.column "created_at",         :datetime
    t.column "submitted",          :boolean
    t.column "has_been_submitted", :boolean,  :default => false
    t.column "assigned_to",        :integer
  end

  create_table "form_types", :force => true do |t|
    t.column "friendly_name",            :string
    t.column "name",                     :string
    t.column "can_have_notes",           :boolean, :default => true
    t.column "can_have_multiple_drafts", :boolean, :default => true
    t.column "draftable",                :boolean, :default => true
    t.column "reeditable",               :boolean, :default => true
  end

  create_table "handbook_acknowledgements", :force => true do |t|
    t.column "digital_signature_id",   :integer
    t.column "digital_signature_hash", :string
    t.column "digital_signature_date", :datetime
  end

  create_table "incident_reports", :force => true do |t|
    t.column "employee_name",     :string
    t.column "incident_date",     :datetime
    t.column "description",       :text
    t.column "manager_sign_id",   :integer
    t.column "manager_sign_hash", :string
    t.column "manager_sign_date", :datetime
  end

  create_table "logs", :force => true do |t|
    t.column "created_at",  :datetime
    t.column "log_type",    :string
    t.column "data",        :string
    t.column "object_id",   :integer
    t.column "object_type", :string
    t.column "agent_id",    :integer
    t.column "agent_type",  :string
  end

  create_table "manager_reports", :force => true do |t|
    t.column "overview",                        :text
    t.column "actual_debit",                    :decimal, :precision => 8, :scale => 2
    t.column "number_of_tans",                  :integer
    t.column "total_sales",                     :decimal, :precision => 8, :scale => 2
    t.column "total_revenue",                   :decimal, :precision => 8, :scale => 2
    t.column "previous_year_sales",             :decimal, :precision => 8, :scale => 2
    t.column "previous_year_tans",              :integer
    t.column "goal_for_month",                  :decimal, :precision => 8, :scale => 2
    t.column "actual_vs_goal_diff_for_month",   :decimal, :precision => 8, :scale => 2
    t.column "action_plan_for_next_month",      :text
    t.column "meetings_training_agenda",        :text
    t.column "cash_error",                      :decimal, :precision => 8, :scale => 2
    t.column "payroll_percent_for_month",       :decimal, :precision => 8, :scale => 2
    t.column "store_inspection_grade",          :string
    t.column "employees",                       :string
    t.column "maintenance_requests",            :string
    t.column "suggestions",                     :text
    t.column "store_needs",                     :text
    t.column "inventory_items_error",           :string
    t.column "action_plan_to_correct_problems", :string
  end

  create_table "notes", :force => true do |t|
    t.column "form_instance_id", :integer
    t.column "author_type",      :string
    t.column "author_id",        :integer
    t.column "text",             :text
    t.column "created_at",       :datetime
    t.column "attachment",       :string
  end

  create_table "notice_of_terminations", :force => true do |t|
    t.column "employee_name",           :string
    t.column "reason_for_termination",  :text
    t.column "manager_signature_id",    :integer
    t.column "manager_signature_hash",  :string
    t.column "manager_signature_date",  :datetime
    t.column "regional_signature_id",   :integer
    t.column "regional_signature_hash", :string
    t.column "regional_signature_date", :datetime
  end

  create_table "performance_reviews", :force => true do |t|
    t.column "employee_name",         :string
    t.column "good_attendance",       :boolean
    t.column "completes_checklists",  :boolean
    t.column "cleaning_schedule",     :boolean
    t.column "understands_packages",  :boolean
    t.column "understands_rotation",  :boolean
    t.column "pleasant_to_clients",   :boolean
    t.column "run_computer",          :boolean
    t.column "paperwork",             :boolean
    t.column "no_shortages",          :boolean
    t.column "follows_instructions",  :boolean
    t.column "open_close_unassisted", :boolean
    t.column "manager_sign_id",       :integer
    t.column "manager_sign_hash",     :string
    t.column "manager_sign_date",     :datetime
    t.column "manager_comments",      :string
    t.column "employee_sign_id",      :integer
    t.column "employee_sign_hash",    :string
    t.column "employee_sign_date",    :datetime
    t.column "employee_comments",     :string
  end

  create_table "sales_reports", :force => true do |t|
    t.column "store_daily_sales",           :decimal, :precision => 8, :scale => 2
    t.column "opening_checklist",           :boolean
    t.column "closing_checklist",           :boolean
    t.column "daily_cleaning",              :boolean
    t.column "goal_for_day",                :decimal, :precision => 8, :scale => 2
    t.column "total_revenue",               :decimal, :precision => 8, :scale => 2
    t.column "actual_vs_goal_diff_for_day", :decimal, :precision => 8, :scale => 2
    t.column "employee_names",              :string,                                :default => "--- \n- \"\"\n"
    t.column "employee_sales",              :string,                                :default => "--- \n- \"\"\n"
    t.column "employee_ppa",                :string,                                :default => "--- \n- \"\"\n"
    t.column "employee_tans",               :string,                                :default => "--- \n- \"\"\n"
    t.column "store_ppa",                   :integer
    t.column "total_tans",                  :integer
    t.column "cash_error",                  :decimal, :precision => 8, :scale => 2
  end

  create_table "stores", :force => true do |t|
    t.column "alias",          :string,   :limit => 25
    t.column "friendly_name",  :string,   :limit => 50
    t.column "address",        :string
    t.column "contact_person", :string,   :limit => 25
    t.column "telephone",      :string,   :limit => 20
    t.column "tax_id",         :string
    t.column "created_at",     :datetime
    t.column "updated_at",     :datetime
    t.column "form_type_ids",  :string,                 :default => "--- []\n\n"
  end

  create_table "time_off_requests", :force => true do |t|
    t.column "time_off_kind",           :string
    t.column "dates_requested",         :string
    t.column "employee_signature_id",   :integer
    t.column "employee_signature_hash", :string
    t.column "employee_signature_date", :datetime
    t.column "admin_review_id",         :integer
    t.column "admin_review_hash",       :string
    t.column "admin_review_date",       :datetime
    t.column "time_left_before_days",   :integer
    t.column "time_left_after_days",    :integer
    t.column "admin_approval_id",       :integer
    t.column "admin_approval_hash",     :string
    t.column "admin_approval_date",     :datetime
    t.column "employee_name",           :string
    t.column "date",                    :date
  end

  create_table "users", :force => true do |t|
    t.column "username",               :string,   :limit => 25
    t.column "friendly_name",          :string,   :limit => 50
    t.column "store_id",               :integer
    t.column "crypted_password",       :string,   :limit => 40
    t.column "salt",                   :string,   :limit => 40
    t.column "social_security_number", :integer,  :limit => 9
    t.column "password_change_date",   :string
    t.column "activated_at",           :datetime
    t.column "created_at",             :datetime
    t.column "updated_at",             :datetime
    t.column "form_type_ids",          :string,                 :default => "--- []\n\n"
    t.column "is_store_admin",         :boolean,                :default => false
  end

  create_table "verbal_warnings", :force => true do |t|
    t.column "employee_name",      :string
    t.column "incident_date",      :datetime
    t.column "description",        :text
    t.column "employee_sign_id",   :integer
    t.column "employee_sign_hash", :string
    t.column "employee_sign_date", :datetime
    t.column "manager_sign_id",    :integer
    t.column "manager_sign_hash",  :string
    t.column "manager_sign_date",  :datetime
  end

  create_table "written_warnings", :force => true do |t|
    t.column "employee_name",      :string
    t.column "incident_date",      :datetime
    t.column "description",        :text
    t.column "employee_sign_id",   :integer
    t.column "employee_sign_hash", :string
    t.column "employee_sign_date", :datetime
    t.column "manager_sign_id",    :integer
    t.column "manager_sign_hash",  :string
    t.column "manager_sign_date",  :datetime
  end

end
