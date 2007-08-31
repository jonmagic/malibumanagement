# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include DatePickerHelper
  include NumberFieldHelper

  def raw_date_picker_field(object, method)
    obj = instance_eval("@#{object}") || object
    value = obj.send(method)
    display_value = value.respond_to?(:strftime) ? value.strftime('%b %d, %Y') : value.to_s
    display_value = '[ choose date ]' if display_value.blank?

    out = hidden_field(object, method)
    out << content_tag('a', display_value, :href => '#',
        :id => "_#{object}_#{method}_link", :class => '_demo_link',
        :onclick => "DatePicker.toggleDatePicker('#{object}_#{method}'); return false;")
    out << content_tag('span', '&nbsp;', :class => 'date_picker', :style => 'display: none',
                      :id => "_#{object}_#{method}_calendar")
    if obj.respond_to?(:errors) and obj.errors.on(method) then
      ActionView::Base.field_error_proc.call(out, nil) # What should I pass ?
    else
      out
    end
  end

  def tab_link_to(name, options = {}, html_options = nil, *parameters_for_method_reference)
    if html_options.kind_of?(Hash)
      active_only_if_equal = html_options.delete(:active_only_if_equal) || false
      normally_hide = html_options.delete(:normally_hide) || false
    else
      active_only_if_equal = false
      normally_hide = false
    end
    url = options.is_a?(String) ? options : self.url_for(options, *parameters_for_method_reference)
    html_options ||= {}
    active = (active_only_if_equal ? request.request_uri == url : request.request_uri =~ /^#{url}/) ? true : false
    html_options[:class] = html_options[:class].blank? ? 'active' : html_options[:class] + ' active' if active
    (!normally_hide || active) ? link_to(name, options, html_options, *parameters_for_method_reference) : '&nbsp;'
  end

  # Use in place of image_tag when you want to show an icon for a file. Call simply as icon_for(filename)
  def icon_for(filename)
    icon_file = File.exists?("#{RAILS_ROOT}/public/images/icons/icon#{File.extname(filename)}.png") ? "/images/icons/icon#{File.extname(filename)}.png" : '/images/icons/icon.any.png'
    image_tag(icon_file, :width=>"50px", :title=>File.basename(filename))
  end

  def the_post_path(options={})
    current_user.kind_of?(Admin) ? admin_post_path(options) : post_path(options)
  end
  def the_js_post_path(options={})
    current_user.kind_of?(Admin) ? formatted_admin_post_path({:format => 'js'}.merge(options)) : formatted_post_path({:format => 'js'}.merge(options))
  end
  def the_js_edit_post_path(options={})
    current_user.kind_of?(Admin) ? formatted_admin_edit_post_path({:format => 'js'}.merge(options)) : formatted_edit_post_path({:format => 'js'}.merge(options))
  end
  def the_js_posts_path(options={})
    current_user.kind_of?(Admin) ? formatted_admin_posts_path({:format => 'js'}.merge(options)) : formatted_posts_path({:format => 'js'}.merge(options))
  end
  def the_attachment_post_path(options={})
    current_user.kind_of?(Admin) ? admin_attachment_post_path(options) : attachment_post_path(options)
  end
  def the_search_posts_path(options={})
    current_user.kind_of?(Admin) ? admin_search_posts_path : search_posts_path
  end
  def the_live_search_posts_path(options={})
    current_user.kind_of?(Admin) ? admin_live_search_posts_path(options) : live_search_posts_path(options)
  end
  def the_new_post_path(options={})
    current_user.kind_of?(Admin) ? admin_new_post_path(options) : new_post_path(options)
  end
end

module ActionView
  module Helpers
    module UrlHelper
      def convert_options_to_javascript!(html_options, url = '')
        confirm, popup, loading = html_options.delete("confirm"), html_options.delete("popup"), html_options.delete("loading")

        method, href = html_options.delete("method"), html_options['href']

        html_options["onclick"] = case
          when confirm && loading
            "if (#{confirm_javascript_function(confirm)}) { #{loading_javascript_function(loading)}return true; };return false;"
          when popup && method
            raise ActionView::ActionViewError, "You can't use :popup and :method in the same link"
          when confirm && popup
            "if (#{confirm_javascript_function(confirm)}) { #{popup_javascript_function(popup)} };return false;"
          when confirm && method
            "if (#{confirm_javascript_function(confirm)}) { #{method_javascript_function(method)} };return false;"
          when loading
            "#{loading_javascript_function(loading)}return true;"
          when confirm
            "return #{confirm_javascript_function(confirm)};"
          when method
            "#{method_javascript_function(method, url, href)}return false;"
          when popup
            popup_javascript_function(popup) + 'return false;'
          else
            html_options["onclick"]
        end
      end
      
      def loading_javascript_function(loading)
        "Control.Modal.open('<div class=\\'loading-dialog\\'><img src=\\'/images/ajax-loader.gif\\' valign=\\'middle\\' />#{escape_javascript(loading)}</div>');"
      end
    end
  end
end

module ActiveRecord
  class Base
    def self.find_by_sql_with_limit(sql, offset, limit)
      sql = sanitize_sql(sql)
      add_limit!(sql, {:limit => limit, :offset => offset})
      find_by_sql(sql)
    end
    def self.count_by_sql_wrapping_select_query(sql)
      sql = sanitize_sql(sql)
      count_by_sql("select count(*) from (#{sql}) as my_table")
    end
  end
end

class String < Object
  def as_status
    Status.new(self)
  end

  def fromCamelCase
    self.to_s.gsub(/(.)([A-Z])/, '\1_\2').downcase
  end

  def l33t
    self.gsub(/[Ii]/, '1').gsub(/[Aa]/, '4').gsub(/[Ee]/, '3').gsub(/[Oo]/, '0')
  end

  def columnize
    self.split(/ +/).each {|w| w.gsub!(/[\.-]/, ''); w.capitalize!}.join('').underscore
  end
end

class Fixnum < Integer
  def as_status
    Status.new(self)
  end
end

class Array < Object
  def count
    self.length
  end
end

class Hash < Object
# Given self and a hash, return the duplicate keys with different values
  def changed_values(hash)
    new_attribs = {}
    self.merge(hash.reject {|k,v| k=='updated_at'}) {|key,old,nw| new_attribs[key] = old unless old == nw}
    new_attribs
  end
end

class Time
  def self.tomorrow
    1.day.from_now
  end
end

