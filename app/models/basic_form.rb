class BasicForm < ActiveRecord::Base
  has_one :instance, :as => :form_data, :class_name => 'FormInstance' # Looks for form_data_id in form_instances, calls it self.instance
# These should be looking for form_data_id == self.id and form_data_type == BasicForm in form_instances, in order to match up with doctor_id/patient_id/form_type_id
  has_many :doctors, :finder_sql => 'SELECT doctors.* FROM doctors,form_instances fi WHERE fi.form_data_id=#{id} AND fi.form_data_type="BasicForm" AND doctors.id=fi.doctor_id'
  has_many :patients, :finder_sql => 'SELECT patients.* FROM patients,form_instances fi WHERE fi.form_data_id=#{id} AND fi.form_data_type="BasicForm" AND patients.id=fi.patient_id'
  has_many :form_types, :finder_sql => 'SELECT form_types.* FROM form_types,form_instances fi WHERE fi.form_data_id=#{id} AND fi.form_data_type="BasicForm" AND form_types.id=fi.form_type_id'
  has_many :notes, :finder_sql => 'SELECT notes.* FROM notes,form_instances fi WHERE fi.form_data_id=#{id} AND fi.form_data_type="BasicForm" AND AND notes.form_instance_id=fi.id'

# Attr_accessible is here to eliminate irrelevant values given by a patient object when attributes are created/updated.
  attr_accessible :account_number, :last_name, :first_name, :middle_initial, :sex, :marital_status, :birth_date, :social_security_number, :address, :city, :state, :zipcode, :telephone, :work_telephone, :work_status, :employment_school, :responsible_last_name, :responsible_first_name, :responsible_middle_initial, :responsible_birth_date, :responsible_social_security_number, :responsible_address, :responsible_city, :responsible_state, :responsible_zipcode, :responsible_telephone, :responsible_work_telephone, :responsible_work_status, :responsible_employment_school, :encounter_form_number, :provider_name, :referring_provider_name, :location, :accident, :accident_date, :admit_date, :discharge_date, :onset_date, :last_menstrual_period, :authorization_number, :new_patient, :emergency, :anesthesia_start_time, :anesthesia_stop_time, :primary_insurance_company, :primary_address, :primary_city, :primary_state, :primary_zipcode, :primary_telephone, :primary_first_name, :primary_middle_initial, :primary_last_name, :primary_relationship, :primary_birth_date, :primary_social_security_number, :primary_contract_number, :primary_plan_number, :primary_group_number, :secondary_insurance_company, :secondary_address, :secondary_city, :secondary_state, :secondary_zipcode, :secondary_telephone, :secondary_first_name, :secondary_middle_initial, :secondary_last_name, :secondary_relationship, :secondary_birth_date, :secondary_social_security_number, :secondary_contract_number, :secondary_plan_number, :secondary_group_number, :tertiary_insurance_company, :tertiary_address, :tertiary_city, :tertiary_state, :tertiary_zipcode, :tertiary_telephone, :tertiary_first_name, :tertiary_middle_initial, :tertiary_last_name, :tertiary_relationship, :tertiary_birth_date, :tertiary_social_security_number, :tertiary_contract_number, :tertiary_plan_number, :tertiary_group_number
  # This includes things such as self.doctor, self.patient, self.form_type

  after_create   :log_create
  after_update   :log_update
  before_destroy :log_destroy

  include FormOperations

  private
    def log_create
      Log.create(:log_type => 'create:BasicForm', :data => {})
    end
    def log_update
      Log.create(:log_type => 'update:BasicForm', :data => {})
    end
    def log_destroy
      Log.create(:log_type => 'destroy:BasicForm', :data => {})
    end

end
