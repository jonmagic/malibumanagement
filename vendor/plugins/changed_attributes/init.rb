require 'changed_attributes'
require 'changed_attribute_validations'
ActiveRecord::Base.send :include, ChangedAttributes
ActiveRecord::Base.class_eval do
  # include ActiveRecord::Validations
  # include ActiveRecord::Locking::Optimistic
  # include ActiveRecord::Locking::Pessimistic
  include ActiveRecord::Callbacks
  # include ActiveRecord::Observing
  # include ActiveRecord::Timestamp
  # include ActiveRecord::Associations
  # include ActiveRecord::Aggregations
  # include ActiveRecord::Transactions
  # include ActiveRecord::Reflection
  # include ActiveRecord::Acts::Tree
  # include ActiveRecord::Acts::List
  # include ActiveRecord::Acts::NestedSet
  # include ActiveRecord::Calculations
  # include ActiveRecord::XmlSerialization
  # include ActiveRecord::AttributeMethods
end
