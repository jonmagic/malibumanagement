require 'is_searchable'
ActiveRecord::Base.send(:include, IsSearchable)
