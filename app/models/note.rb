class Note < ActiveRecord::Base
  belongs_to :form_instance
  belongs_to :author, :polymorphic => true
  file_column :attachment, :root_path => RAILS_ROOT+"/attachments"

end
