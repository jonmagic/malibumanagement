def with(*objects)
  yield(*objects)
  return *objects
end

require 'goto_billing/connection'
module GotoBilling
  class GotoBillingError < StandardError #:nodoc:
  end
  class AttributeError < GotoBillingError
  end

  class Base
    class << self
      def has_attributes(*attrs)
        attrs.each do |atr|
          self.class_eval <<-endit
            def #{atr}
              @attributes['#{atr}']
            end
            
            def #{atr}=(v)
              @attributes['#{atr}'] = v
            end
          endit
        end
      end

      def site
        @site
      end

      # Sets the URI of the REST resources to map for this class to the value in the +site+ argument.
      # The site variable is required ActiveResource's mapping to work.
      def site=(site)
        @connection = nil
        @site = site.nil? ? nil : create_site_uri_from(site)
      end

      def connection(refresh = false)
        @connection = Connection.new(site, '70.238.94.50', format) if refresh || @connection.nil?
        @connection
      end

      def format
        GotoBilling::Formats[:xml]
      end

      def headers
        @headers ||= {}
      end

      # Transforms attribute key names into a more humane format, such as "First name" instead of "first_name". Example:
      #   Person.human_attribute_name("first_name") # => "First name"
      # Deprecated in favor of just calling "first_name".humanize
      def human_attribute_name(attribute_key_name) #:nodoc:
        attribute_key_name.humanize
      end

      private
        # Builds the query string for the request.
        def query_string(options)
          "?#{options.to_query}" unless options.nil? || options.empty? 
        end

        # Accepts a URI and creates the site URI from that.
        def create_site_uri_from(site)
          site.is_a?(URI) ? site.dup : URI.parse(site)
        end
    end

    def initialize(attrs={})
      @attributes = {}
      self.attributes = attrs unless attrs.nil?
      self
    end

    def attributes=(new_attributes)
      return if new_attributes.nil?
      with(new_attributes.dup) do |a|
        a.stringify_keys!
        a.each {|k,v| send(k + "=", a.delete(k)) if self.respond_to?("#{k}=")}
        self.response = a # All the rest of the attributes go into response
      end
    end

    def attributes
      @attributes
    end

    def http_attributes
      http_attr = {}
      self.class.http_attribute_mapping.each do |k,v|
        http_attr[self.class.http_attribute_mapping[k.to_s]] = self.http_attribute_convert(k.to_s) unless self.http_attribute_convert(k.to_s).nil?
      end
      http_attr
    end

    def submit
      self.response = Goto::Response.new(connection.get(self.class.site.path, self.http_attributes))
    end
    alias :save :submit
    alias :commit :submit

    def merge_response(response)
      self.status = response['status'] if response['status']
      self.order_number = response['order_number'] if response['order_number']
      self.term_code = response['term_code'] if response['term_code']
      self.amount = response['amount'] if response['amount']
      self.tran_date = response['tran_date'] if response['tran_date']
      self.tran_time = response['tran_time'] if response['tran_time']
      self.transaction_id = response['invoice_id'] if response['invoice_id']
      self.auth_code = response['auth_code'] if response['auth_code']
      self.description = response['description'] if response['description']
    end
    alias :response= :merge_response

    def response
      Goto::Response.new(self.attributes)
    end

    def invalid?
      !valid?
    end
    def submitted?
      ['G', 'R', 'D', 'C'].include?(response['status'])
    end
    def should_retry?
      !submitted?
    end
    def accepted?
      submitted? && (response['status'] == 'R' || response['status'] == 'G')
    end
    def paid_now?
      submitted? && response['status'] == 'G'
    end
    def declined?
      submitted? ? !accepted? : false
    end
    def duplicate?
      response['description'] =~ /^DUPLICATE_TRANSACTION_ALREADY_APPROVED/ ? true : false
    end

    protected
      def connection(refresh = false)
        self.class.connection(refresh)
      end
  end
end
