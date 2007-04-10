class ManagerReport < ActiveRecord::Base
  has_one :instance, :as => :form_data, :class_name => 'FormInstance' # Looks for form_data_id in form_instances, calls it self.instance
#These are actually not necessary!!
  has_many :stores, :finder_sql => 'SELECT stores.* FROM stores,form_instances fi WHERE fi.form_data_id=#{id} AND fi.form_data_type="ManagerReport" AND stores.id=fi.store_id'
  has_many :form_types, :finder_sql => 'SELECT form_types.* FROM form_types,form_instances fi WHERE fi.form_data_id=#{id} AND fi.form_data_type="ManagerReport" AND form_types.id=fi.form_type_id'
  has_many :notes, :finder_sql => 'SELECT notes.* FROM notes,form_instances fi WHERE fi.form_data_id=#{id} AND fi.form_data_type="ManagerReport" AND AND notes.form_instance_id=fi.id'
  has_many :logs, :as => 'object'

# Attr_accessible is here to eliminate irrelevant values given by a patient object when attributes are created/updated.
  attr_accessible :overview, :actual_debit, :number_of_tans, :total_sales, :total_revenue, :previous_year_sales, :previous_year_tans, :goal_for_month, :action_plan_for_next_month, :meetings_training_agenda, :cash_error, :payroll_percent_for_month, :store_inspection_grade, :employees, :maintenance_requests, :suggestions, :store_needs, :inventory_items_error, :action_plan_to_correct_problems

end
