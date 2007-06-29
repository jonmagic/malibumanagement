class FormInstance < ActiveRecord::Base
  belongs_to :user       #Uses column user_id
  belongs_to :store     #Uses column store_id
  belongs_to :form_type  #Uses column form_type_id
  belongs_to :data, :polymorphic => true, :dependent => :destroy #(, :extend => ...)  #Uses columns data_type, data_id
  has_many :notes, :dependent => :destroy
  has_many :logs, :as => 'object'
  belongs_to :assigned, :class_name => 'User', :foreign_key => 'assigned_to'

  before_save :unassign_if_submitted

  def validate
    errors.add_to_base("Form data is not valid") unless self.data.valid?
  end

#Creating a new FormInstance:
#  FormInstance.new(:store => Store, :user => current_user, :form_type => FormType, [[:data => AUTO-CREATES NEW]])
#Automagically create the form data record whenever a FormInstance is created, and then automagically destroy it when the FormInstance is destroyed.
#  The form data record will always be tied to self.data
  def initialize(args)
    ft = args[:form_type]
    args[:form_type] = FormType.find_by_name(args[:form_type].to_s)
    super(args)
    self.data = ft.new unless !(args.kind_of? Hash) or ft.nil?
  end

  def status
    self.status_number.as_status.word('lowercase short singular')
  end
  def status=(value)
    return nil if value.as_status.number == 0 #0 is a valid status text (all), but not valid for forms
    self.status_number = value.kind_of?(Status) ? value.number : (value.as_status.number || self.status_number)
    self.has_been_submitted = 1 if self.status_number > 1
    self.status_number
  end
  def has_been_submitted?
    self.has_been_submitted
  end

  def unassign_if_submitted
    self.assigned_to = nil if self.status_number > 1
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
    "Form #{self.data_type}, ##{self.id}"
  end

end
