class FormInstance < ActiveRecord::Base
  belongs_to :user       #Uses column user_id
  belongs_to :store     #Uses column store_id
  belongs_to :form_type  #Uses column form_type_id
  belongs_to :form_data, :polymorphic => true, :dependent => :destroy #(, :extend => ...)  #Uses columns form_data_type, form_data_id
  has_many :notes, :dependent => :destroy
  has_many :logs, :as => 'object'

#Creating a new FormInstance:
#  FormInstance.new(:store => Store, :user => current_user, :form_type => FormType, [[:form_data => AUTO-CREATES NEW]])
#Automagically create the form data record whenever a FormInstance is created, and then automagically destroy it when the FormInstance is destroyed.
#  The form data record will always be tied to self.form_data
  def initialize(args)
    self.form_data = args[:form_type].new unless !(args.kind_of? Hash) or args[:form_type].nil?
    args[:form_type] = FormType.find_by_name(args[:form_type].to_s)
    super(args)
  end

  def status
    self.status_number.as_status.word('lowercase short singular')
  end
  def status=(value)
    return nil if value.as_status.number == 0 #0 is a valid status text (all), but not valid for forms
    self.status_number = value.as_status.number || self.status_number
    self.has_been_submitted = 1 if self.status_number > 1
    self.status_number
  end
  def has_been_submitted?
    self.has_been_submitted
  end

  def admin_visual_identifier
    "<span title='#{self.form_identifier}'>#{self.store.friendly_name} &gt; #{self.form_type.friendly_name} #{self.created_at.strftime('%A, %B %d, %Y')}</span>"
  end
  def visual_identifier
    "<span title='#{self.form_identifier}'>#{self.form_type.friendly_name} &gt; #{self.created_at.strftime('%A, %B %d, %Y')}</span>"
  end
  def visual_identifier_with_status
    "<span title='#{self.form_identifier}'>(#{self.status}) #{self.created_at.strftime('%A, %B %d, %Y')}</span>"
  end

  def form_identifier
    "Form #{self.form_data_type}, ##{self.id}"
  end

end
