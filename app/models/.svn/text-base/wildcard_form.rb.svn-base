class WildcardForm < ActiveRecord::Base
  has_one :instance, :as => :data, :class_name => 'FormInstance'
  has_many :logs, :as => 'object'
  attr_accessor :save_status
  attr_accessible :description
end
