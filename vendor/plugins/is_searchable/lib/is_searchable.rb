module IsSearchable
  def self.included(base)
    base.extend(IncludeClassMethods)
  end

  module IncludeClassMethods
    def is_searchable(options)
      @query_condition = options[:by_query]
      @filter_comparisons = options[:filters] || options[:and_filters] || {}
      @method_filters = options[:method_filters] || {}
      self.extend ModelClassMethods
    end

    module ModelClassMethods
      def search_count(query, options={})
        filters = options[:filters] || {}
# ActionController::Base.logger.info(options[:filters].inspect)
        if filters.keys.sort == (filters.keys.sort - @method_filters.keys)
          # doesn't include any method filters
# ActionController::Base.logger.info('_bulk_search')
          return _bulk_count(query, options)
        else
          # includes method filters: Do the whole search, but it's cached, so it really only happens once.
# ActionController::Base.logger.info('_method_search')
          return _method_search(query, options).length
        end
      end
      def search(query, options={})
        filters = options[:filters] || {}
# ActionController::Base.logger.info(options[:filters].inspect)
        if filters.keys.sort == (filters.keys.sort - @method_filters.keys)
          # doesn't include any method filters
# ActionController::Base.logger.info('_bulk_search')
          return _bulk_search(query, options)
        else
          # includes method filters
# ActionController::Base.logger.info('_method_search')
          return _method_search(query, options)
        end
      end

# sorta private methods
      def _bulk_count(query, options={})
        filters = options[:filters] || {}
# ActionController::Base.logger.info(options[:filters].inspect)
# puts "SELECT COUNT(*) FROM (SELECT #{self.table_name}.* FROM #{self.table_name} #{render_condition_for_query_and_filters(query, filters)} GROUP BY #{self.table_name}.id) as tmpA"
        self.count_by_sql("SELECT COUNT(*) FROM (SELECT #{self.table_name}.* FROM #{self.table_name} #{render_condition_for_query_and_filters(query, filters)} GROUP BY #{self.table_name}.id) as tmpA")
      end
      def _bulk_search(query, options={})
        @search_caches ||= {}
        limit = options[:limit] || 0
        offset = options[:offset] || 0
        filters = options[:filters] || {}
# ActionController::Base.logger.info(options[:filters].inspect)
# puts "SELECT #{self.table_name}.* FROM #{self.table_name} #{render_condition_for_query_and_filters(query, filters)} GROUP BY #{self.table_name}.id LIMIT #{limit} OFFSET #{offset}"
# ActionController::Base.logger.info "SELECT #{self.table_name}.* FROM #{self.table_name} #{render_condition_for_query_and_filters(query, filters)} GROUP BY #{self.table_name}.id LIMIT #{limit} OFFSET #{offset}"
        sql = "SELECT #{self.table_name}.* FROM #{self.table_name} #{render_condition_for_query_and_filters(query, filters)} GROUP BY #{self.table_name}.id"
        sql = sql+" LIMIT #{limit}" if limit > 0
        sql = sql+" OFFSET #{offset}" if offset > 0
        @search_caches[query+'_'+filters.values.join('-')] ||= self.find_by_sql(sql)
      end
      def _method_search(query, options={})
        @search_caches ||= {}
        limit = options[:limit] || 0
        offset = options[:offset] || 0
        filters = options[:filters] || {}
# ActionController::Base.logger.info(options[:filters].inspect)
        results = []

        begin
          next_rec = self.find_by_sql("SELECT #{self.table_name}.* FROM #{self.table_name} #{render_condition_for_query_and_filters(query, filters)} GROUP BY #{self.table_name}.id LIMIT 1 OFFSET #{results.length}")
          results << next_rec if true # Do the method search methods and add the record to results if the methods all return true.
        end until next_rec.nil? || (limit > 0 && results.length == limit)

        @search_caches[query+'_'+options[:filters].each_value.join('-')] ||= results[offset-1..results.length]
      end
      def render_condition_for_query_and_filters(query, filters) #search in: first_name, last_name, identifier
# ActionController::Base.logger.info("Filters in query_and_filters: #{filters.inspect}")
        condition = [
          query == '' ? nil : "(#{self.render_query_condition(query)})",
          filters.keys.length == 0 ? nil : "(#{self.render_filter_condition(filters)})"
        ].compact.join(' AND ')
ActionController::Base.logger.info("**Search condition: #{condition == '' ? '(none)' : 'WHERE '+condition}")
        condition == '' ? '' : 'WHERE '+condition
      end
      def render_query_condition(query)
        @query_condition.to_s == '' ? nil : self.replace_named_bind_variables(@query_condition, {:query => query, :like_query => '%' + query.to_s + '%'})
      end
      def render_filter_condition(filters)
# ActionController::Base.logger.info("Filters in render_filter_condition: #{filters.inspect}")
# puts "Filters in render_filter_condition: #{filters.inspect}"
# ActionController::Base.logger.info("@filter_comparisons: #{@filter_comparisons.inspect}")
# puts "@filter_comparisons: #{@filter_comparisons.inspect}"
        condition = [filters.reject {|f,v| @filter_comparisons[f].nil? }.collect do |key,val|
          val = "%#{val}%" if @filter_comparisons[key.to_s] =~ /LIKE/
          self.replace_bind_variables(@filter_comparisons[key.to_s], [val])
        end].flatten.compact.join(' AND ')
        condition == '' ? nil : condition
      end
    end
  end
end