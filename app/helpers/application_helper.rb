# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  include DatePickerHelper

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

  def color_amount(amount)
    amount = 0 if amount.nil?
    amount.to_f > 0 ? "<span class='number_positive'>#{amount}</span>" : (amount.to_f == 0 ? "<span class='number_zero'>#{amount}</span>" : "<span class='number_negative'>#{amount}</span>")
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
