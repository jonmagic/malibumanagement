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
        @connection = Connection.new(site, '158796', 'y4nn0', '70.238.94.50', format) if refresh || @connection.nil?
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
      @new_record = true
      self
    end

    def attributes=(new_attributes)
      return if new_attributes.nil?
      with(new_attributes.dup) do |a|
        a.stringify_keys!
        a.each {|k,v| send(k + "=", v)}
      end
    end

    def submit
      connection.get(self.class.site.path, self.http_attributes)
    end
    alias :save :submit
    alias :commit :submit

    def attributes
      @attributes
    end

    def http_attributes
      http_attr = {}
      self.attributes.each do |k,v|
        http_attr[self.class.http_attribute_mapping[k.to_s]] = self.http_attribute_convert(k.to_s) unless self.http_attribute_convert(k.to_s).nil?
      end
      # http_attr.extend HttpAttributes
      http_attr
    end

    # module HttpAttributes
    #   def to_query
    #     '?' + self.map {|k,v| "#{k.to_s}=#{v.to_s}"}.join("&")
    #   end
    # end

    protected
      def connection(refresh = false)
        self.class.connection(refresh)
      end
  end
end
