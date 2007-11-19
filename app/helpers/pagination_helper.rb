module ActionView
  module Helpers
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
