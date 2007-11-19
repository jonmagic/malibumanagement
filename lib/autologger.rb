#This module requires a 'logs' table...
# create_table "logs", :force => true do |t|
#   t.column "created_at",  :datetime
#   t.column "log_type",    :string
#   t.column "data",        :string
#   t.column "object_id",   :integer
#   t.column "object_type", :string
#   t.column "agent_id",    :integer
#   t.column "agent_type",  :string
# end
#...and a model that has the minimal of...
# class Log < ActiveRecord::Base
#   serialize :data
# end
#...with optional
#   belongs_to :object, :polymorphic => true #optional
#   belongs_to :agent,  :polymorphic => true #optional

class Hash < Object
# Given self and a hash, return the duplicate keys with different values
  def changed_values(hash)
    new_attribs = {}
    self.merge(hash.reject {|k,v| k=='updated_at'}) {|key,old,nw| new_attribs[key] = old unless old == nw}
    new_attribs
  end
end

module Autologger
  def self.append_features(base)
    base.after_create do |model|
      unless model.class.to_s.humanize == 'Log' or model.class.instance_variable_get('@nologging') or @migrating == true
        old_obj = model.class.find_by_id(model.id)
        Log.create(:log_type => "create:#{model.class.to_s.humanize}", :data => {:new_attributes => model.attributes.changed_values(old_obj.attributes)}, :object => old_obj, :agent => Thread.current['user'])
      end
    end
    base.before_update do |model|
      unless model.class.to_s.humanize == 'Log' or model.class.instance_variable_get('@nologging') or @migrating == true
        old_obj = model.class.find_by_id(model.id)
        Log.create(:log_type => "update:#{model.class.to_s.humanize}", :data => {:old_attributes => old_obj.attributes.changed_values(model.attributes), :new_attributes => model.attributes.changed_values(old_obj.attributes)}, :object => old_obj, :agent => Thread.current['user']) unless model.attributes.changed_values(old_obj.attributes).empty?
      end
    end
    base.before_destroy do |model|
      unless model.class.to_s.humanize == 'Log' or model.class.instance_variable_get('@nologging') or @migrating == true
        old_obj = model.class.find_by_id(model.id)
        Log.create(:log_type => "destroy:#{model.class.to_s.humanize}", :data => {:old_attributes => old_obj.attributes.changed_values(model.attributes)}, :object => old_obj, :agent => Thread.current['user'])
      end
    end
  end
end
