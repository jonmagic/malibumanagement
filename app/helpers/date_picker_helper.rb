module DatePickerHelper
end
module ActionView
  module Helpers
    module FormHelper
      def date_picker_field(object_name, method, options = {})
        InstanceTag.new(object_name, method, self, nil, options.delete(:object)).to_date_picker_field_tag(options)
      end
    end

    class InstanceTag
      def to_date_picker_field_tag(options = {})
        options = DEFAULT_TEXT_AREA_OPTIONS.merge(options.stringify_keys)
        add_default_name_and_id(options)
        value = options.delete('value') || value_before_type_cast(object)
        display_value = value.respond_to?(:strftime) ? value.strftime('%b %d, %Y') : value.to_s
        display_value = '[ choose date ]' if display_value.blank?

        add_default_name_and_id(options)

        out = tag('input', 'name' => options["name"], 'id' => options["id"], 'type' => 'hidden', 'value' => value, 'onchange' => options['onchange'])
        out << content_tag('a', display_value, :href => '#',
            :id => "_#{options['id']}_link", :class => '_date_picker_link',
            :onclick => "DatePicker.toggleDatePicker('#{options['id']}'); return false;")
        out << content_tag('span', '&nbsp;', :class => 'date_picker', :style => 'display: none',
                          :id => "_#{options['id']}_calendar")
        if object.respond_to?(:errors) and object.errors.on(method) then
          ActionView::Base.field_error_proc.call(out, nil) # What should I pass ?
        else
          out
        end
      end
    end

    class FormBuilder
      def date_picker_field(method, options = {})
        @template.date_picker_field(@object_name, method, options.merge(:object => @object))
      end
    end

    module PaginationHelper
      def remote_pagination_links(paginator, options={}, html_options={})
        links = pagination_links_each(paginator, options) do |n|
          ins_options = (options || DEFAULT_OPTIONS).clone
          ins_options[:url] = ins_options[:url]+"&page=#{n}"
          link_to_remote(n.to_s, ins_options, html_options)
        end
        links.nil? ? nil : "Page: #{links}"
      end
    end
  end
end
