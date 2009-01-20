class Post < ActiveRecord::Base
  belongs_to :author, :polymorphic => true
  file_column :attachment, :root_path => RAILS_ROOT+"/attachments"
end
