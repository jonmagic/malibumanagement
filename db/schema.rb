# This file is autogenerated. Instead of editing this file, please use the
# migrations feature of ActiveRecord to incrementally modify your database, and
# then regenerate this schema definition.

ActiveRecord::Schema.define(:version => 11) do

  create_table "admins", :force => true do |t|
    t.column "username",         :string
    t.column "friendly_name",    :string,   :limit => 50
    t.column "email",            :string
    t.column "crypted_password", :string,   :limit => 40
    t.column "salt",             :string,   :limit => 40
    t.column "created_at",       :datetime
    t.column "updated_at",       :datetime
    t.column "activation_code",  :string,   :limit => 40
    t.column "activated_at",     :datetime
  end

  create_table "basic_forms", :force => true do |t|
    t.column "doctor_id",                          :integer
    t.column "status",                             :integer
    t.column "account_number",                     :string
    t.column "last_name",                          :string
    t.column "first_name",                         :string
    t.column "middle_initial",                     :string
    t.column "sex",                                :string
    t.column "marital_status",                     :string
    t.column "birth_date",                         :date
    t.column "social_security_number",             :string
    t.column "address",                            :string
    t.column "city",                               :string
    t.column "state",                              :string
    t.column "zipcode",                            :string
    t.column "telephone",                          :string
    t.column "work_telephone",                     :string
    t.column "work_status",                        :string
    t.column "employment_school",                  :string
    t.column "responsible_last_name",              :string
    t.column "responsible_first_name",             :string
    t.column "responsible_middle_initial",         :string
    t.column "responsible_birth_date",             :date
    t.column "responsible_social_security_number", :string
    t.column "responsible_address",                :string
    t.column "responsible_city",                   :string
    t.column "responsible_state",                  :string
    t.column "responsible_zipcode",                :string
    t.column "responsible_telephone",              :string
    t.column "responsible_work_telephone",         :string
    t.column "responsible_work_status",            :string
    t.column "responsible_employment_school",      :string
    t.column "encounter_form_number",              :string
    t.column "provider_name",                      :string
    t.column "referring_provider_name",            :string
    t.column "location",                           :string
    t.column "accident",                           :string
    t.column "accident_date",                      :date
    t.column "admit_date",                         :date
    t.column "discharge_date",                     :date
    t.column "onset_date",                         :date
    t.column "last_menstrual_period",              :date
    t.column "authorization_number",               :string
    t.column "new_patient",                        :boolean
    t.column "emergency",                          :boolean
    t.column "anesthesia_start_time",              :datetime
    t.column "anesthesia_stop_time",               :datetime
    t.column "primary_insurance_company",          :string
    t.column "primary_address",                    :string
    t.column "primary_city",                       :string
    t.column "primary_state",                      :string
    t.column "primary_zipcode",                    :string
    t.column "primary_telephone",                  :string
    t.column "primary_first_name",                 :string
    t.column "primary_middle_initial",             :string
    t.column "primary_last_name",                  :string
    t.column "primary_relationship",               :string
    t.column "primary_birth_date",                 :string
    t.column "primary_social_security_number",     :string
    t.column "primary_contract_number",            :string
    t.column "primary_plan_number",                :string
    t.column "primary_group_number",               :string
    t.column "secondary_insurance_company",        :string
    t.column "secondary_address",                  :string
    t.column "secondary_city",                     :string
    t.column "secondary_state",                    :string
    t.column "secondary_zipcode",                  :string
    t.column "secondary_telephone",                :string
    t.column "secondary_first_name",               :string
    t.column "secondary_middle_initial",           :string
    t.column "secondary_last_name",                :string
    t.column "secondary_relationship",             :string
    t.column "secondary_birth_date",               :string
    t.column "secondary_social_security_number",   :string
    t.column "secondary_contract_number",          :string
    t.column "secondary_plan_number",              :string
    t.column "secondary_group_number",             :string
    t.column "tertiary_insurance_company",         :string
    t.column "tertiary_address",                   :string
    t.column "tertiary_city",                      :string
    t.column "tertiary_state",                     :string
    t.column "tertiary_zipcode",                   :string
    t.column "tertiary_telephone",                 :string
    t.column "tertiary_first_name",                :string
    t.column "tertiary_middle_initial",            :string
    t.column "tertiary_last_name",                 :string
    t.column "tertiary_relationship",              :string
    t.column "tertiary_birth_date",                :string
    t.column "tertiary_social_security_number",    :string
    t.column "tertiary_contract_number",           :string
    t.column "tertiary_plan_number",               :string
    t.column "tertiary_group_number",              :string
  end

  create_table "doctors", :force => true do |t|
    t.column "alias",          :string,   :limit => 25
    t.column "friendly_name",  :string,   :limit => 50
    t.column "encryption_key", :binary
    t.column "address",        :string
    t.column "contact_person", :string,   :limit => 25
    t.column "telephone",      :string,   :limit => 20
    t.column "tax_id",         :string
    t.column "created_at",     :datetime
    t.column "updated_at",     :datetime
  end

  create_table "doctors_form_types", :force => true do |t|
    t.column "doctor_id",    :integer
    t.column "form_type_id", :integer
  end

  create_table "form_types", :force => true do |t|
    t.column "friendly_name",   :string
    t.column "model",           :string
    t.column "required_fields", :string
    t.column "can_have_notes",  :boolean
  end

  create_table "notes", :force => true do |t|
    t.column "form_type",   :integer
    t.column "form_id",     :integer
    t.column "author_type", :integer
    t.column "author_id",   :integer
    t.column "text",        :text
    t.column "created_at",  :datetime
  end

  create_table "pages", :force => true do |t|
    t.column "title", :string
    t.column "body",  :text
    t.column "stub",  :string
  end

  create_table "patients", :force => true do |t|
    t.column "account_number",                   :string
    t.column "last_name",                        :string
    t.column "first_name",                       :string
    t.column "middle_initial",                   :string
    t.column "sex",                              :string
    t.column "marital_status",                   :string
    t.column "birth_date",                       :date
    t.column "social_security_number",           :string
    t.column "address",                          :string
    t.column "city",                             :string
    t.column "state",                            :string
    t.column "zipcode",                          :string
    t.column "telephone",                        :string
    t.column "work_telephone",                   :string
    t.column "work_status",                      :string
    t.column "employment_school",                :string
    t.column "provider_name",                    :string
    t.column "referring_provider_name",          :string
    t.column "location",                         :string
    t.column "authorization_number",             :string
    t.column "primary_insurance_company",        :string
    t.column "primary_address",                  :string
    t.column "primary_city",                     :string
    t.column "primary_state",                    :string
    t.column "primary_zipcode",                  :string
    t.column "primary_telephone",                :string
    t.column "primary_first_name",               :string
    t.column "primary_middle_initial",           :string
    t.column "primary_last_name",                :string
    t.column "primary_relationship",             :string
    t.column "primary_birth_date",               :string
    t.column "primary_social_security_number",   :string
    t.column "primary_contract_number",          :string
    t.column "primary_plan_number",              :string
    t.column "primary_group_number",             :string
    t.column "secondary_insurance_company",      :string
    t.column "secondary_address",                :string
    t.column "secondary_city",                   :string
    t.column "secondary_state",                  :string
    t.column "secondary_zipcode",                :string
    t.column "secondary_telephone",              :string
    t.column "secondary_first_name",             :string
    t.column "secondary_middle_initial",         :string
    t.column "secondary_last_name",              :string
    t.column "secondary_relationship",           :string
    t.column "secondary_birth_date",             :string
    t.column "secondary_social_security_number", :string
    t.column "secondary_contract_number",        :string
    t.column "secondary_plan_number",            :string
    t.column "secondary_group_number",           :string
    t.column "tertiary_insurance_company",       :string
    t.column "tertiary_address",                 :string
    t.column "tertiary_city",                    :string
    t.column "tertiary_state",                   :string
    t.column "tertiary_zipcode",                 :string
    t.column "tertiary_telephone",               :string
    t.column "tertiary_first_name",              :string
    t.column "tertiary_middle_initial",          :string
    t.column "tertiary_last_name",               :string
    t.column "tertiary_relationship",            :string
    t.column "tertiary_birth_date",              :string
    t.column "tertiary_social_security_number",  :string
    t.column "tertiary_contract_number",         :string
    t.column "tertiary_plan_number",             :string
    t.column "tertiary_group_number",            :string
  end

  create_table "users", :force => true do |t|
    t.column "username",             :string,   :limit => 25
    t.column "friendly_name",        :string,   :limit => 50
    t.column "doctor_id",            :integer
    t.column "email",                :string
    t.column "crypted_password",     :string,   :limit => 40
    t.column "salt",                 :string,   :limit => 40
    t.column "key_diff",             :binary
    t.column "status",               :string
    t.column "password_change_date", :string
    t.column "activation_code",      :string,   :limit => 40
    t.column "activated_at",         :datetime
    t.column "created_at",           :datetime
    t.column "updated_at",           :datetime
  end

end
