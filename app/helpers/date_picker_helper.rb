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
      def simple_remote_pagination_links(paginator, options={}, html_options={})
        simple_pagination_links_each(paginator, options) do |n, word|
          ins_options = (options || DEFAULT_OPTIONS).clone
          ins_options[:url] = ins_options[:url]+"&page=#{n}"
          link_to_remote(word, ins_options, html_options)
        end.to_s
      end

      def remote_pagination_links(paginator, options={}, html_options={})
        links = pagination_links_each(paginator, options) do |n|
          ins_options = (options || DEFAULT_OPTIONS).clone
          ins_options[:url] = ins_options[:url]+"&page=#{n}"
          link_to_remote(n.to_s, ins_options, html_options)
        end
        links.nil? ? nil : "Page: #{links}"
      end

      # Iterate through the pages of a given +paginator+, invoking a
      # block for each page number that needs to be rendered as a link.
      def simple_pagination_links_each(paginator, options)
        options = DEFAULT_OPTIONS.merge(options)
        link_to_current_page = options[:link_to_current_page]
        always_show_anchors = options[:always_show_anchors]
        previous_text = options[:previous_text] || '&lt;Previous'
        next_text = options[:next_text] || 'Next&gt;'
        first_text = options[:first_text] || '&lt;&lt;First'
        last_text = options[:last_text] || 'Last&gt;&gt;'
        between_text = options[:between_text]

        current_page = paginator.current_page
        window_pages = current_page.window(options[:window_size]).pages

        return if window_pages.length <= 1 unless link_to_current_page
        
        first, last = paginator.first, paginator.last
        
        html = ''
        if not window_pages[0].first?
          html << yield(first.number, first_text)
          html << ' '
        end
        
        previous_done = false
        next_done = false
        window_pages.each do |page|
          if page < current_page && page == first
            html << yield(page.number, first_text)
            html << ' '
          elsif page < current_page && page > first && !previous_done
            html << yield(page.number, previous_text)
            html << ' '
            previous_done = true
          elsif page > current_page && page < last && !next_done
            html << between_text << ' ' if between_text
            html << yield(page.number, next_text)
            html << ' '
            next_done = true
          elsif page > current_page && page == last
            html << between_text << ' ' if between_text && !next_done
            html << yield(page.number, last_text)
          end
        end
        if not window_pages[-1].last? 
          html << yield(last.number, last_text)
        end

        html << between_text if between_text && !next_done && current_page == last
        
        html
      end

      def page_x_of_y(paginator, options={})
        "Page #{paginator.current_page.number} of #{paginator.last.number}"
      end
    end
  end
end
