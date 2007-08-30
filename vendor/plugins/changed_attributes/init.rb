require 'changed_attributes'
require 'changed_attribute_validations'
ActiveRecord::Base.send :include, ChangedAttributes
