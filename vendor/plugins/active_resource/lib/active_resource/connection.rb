require 'net/https'
require 'date'
require 'time'
require 'uri'
require 'benchmark'

module ActiveResource
  class ConnectionError < StandardError # :nodoc:
    attr_reader :response

    def initialize(response, message = nil)
      @response = response
      @message  = message
    end

    def to_s
      "Failed with #{response.code}"
    end
  end

  # 4xx Client Error
  class ClientError < ConnectionError; end # :nodoc:
  
  # 404 Not Found
  class ResourceNotFound < ClientError; end # :nodoc:
  
  # 409 Conflict
  class ResourceConflict < ClientError; end # :nodoc:

  # 5xx Server Error
  class ServerError < ConnectionError; end # :nodoc:

  # 405 Method Not Allowed
  class MethodNotAllowed < ClientError # :nodoc:
    def allowed_methods
      @response['Allow'].split(',').map { |verb| verb.strip.downcase.to_sym }
    end
  end

  # Class to handle connections to remote web services.
  # This class is used by ActiveResource::Base to interface with REST
  # services.
  class Connection
    attr_reader :site

    class << self
      def requests
        @@requests ||= []
      end
      
      def default_header
        class << self ; attr_reader :default_header end
        @default_header = { 'Content-Type' => 'application/xml' }
      end
    end

    # The +site+ parameter is required and will set the +site+
    # attribute to the URI for the remote resource service.
    def initialize(site)
      raise ArgumentError, 'Missing site URI' unless site
      self.site = site
    end

    # Set URI for remote service.
    def site=(site)
      @site = site.is_a?(URI) ? site : URI.parse(site)
    end

    # Execute a GET request.
    # Used to get (find) resources.
    def get(path, headers = {})
ActionController::Base.logger.info "GET from #{path}..."
      xml_from_response(request(:get, path, build_request_headers(headers)))
    end

    # Execute a DELETE request (see HTTP protocol documentation if unfamiliar).
    # Used to delete resources.
    def delete(path, headers = {})
ActionController::Base.logger.info "DELETE to #{path}..."
      request(:delete, path, build_request_headers(headers))
    end

    # Execute a PUT request (see HTTP protocol documentation if unfamiliar).
    # Used to update resources.
    def put(path, body = '', headers = {})
ActionController::Base.logger.info "PUT to #{path}..."
      request(:put, path, body.to_s, build_request_headers(headers))
    end

    # Execute a POST request.
    # Used to create new resources.
    def post(path, body = '', headers = {})
ActionController::Base.logger.info "POST to #{path}..."
      request(:post, path, body.to_s, build_request_headers(headers))
    end

    def xml_from_response(response)
      from_xml_data(Hash.from_xml(response.body))
    end

    private
      # Makes request to remote service.
      def request(method, path, *arguments)
        logger.info "#{method.to_s.upcase} #{site.scheme}://#{site.host}:#{site.port}#{path}" if logger
        result = nil
        time = Benchmark.realtime { result = http.send(method, path, *arguments) }
        logger.info "--> #{result.code} #{result.message} (#{result.body.length}b %.2fs)" % time if logger
        handle_response(result)
      end

      # Handles response and error codes from remote service.
      def handle_response(response)
        case response.code.to_i
          when 200...400
            response
          when 404
            raise(ResourceNotFound.new(response))
          when 405
            raise(MethodNotAllowed.new(response))
          when 409
            raise(ResourceConflict.new(response))
          when 422
            raise(ResourceInvalid.new(response))
          when 401...500
            raise(ClientError.new(response))
          when 500...600
            raise(ServerError.new(response))
          else
            raise(ConnectionError.new(response, "Unknown response code: #{response.code}"))
        end
      end

      # Creates new (or uses currently instantiated) Net::HTTP instance for communication with
      # remote service and resources.
      def http
        unless @http
          @http             = Net::HTTP.new(@site.host, @site.port)
          @http.use_ssl     = @site.is_a?(URI::HTTPS)
          @http.verify_mode = OpenSSL::SSL::VERIFY_NONE if @http.use_ssl
        end
        @http.open_timeout = 15

        @http
      end
      
      # Builds headers for request to remote service.
      def build_request_headers(headers)
        authorization_header.update(self.class.default_header).update(headers)
      end
      
      # Sets authorization header; authentication information is pulled from credentials provided with site URI.
      def authorization_header
        (@site.user || @site.password ? { 'Authorization' => 'Basic ' + ["#{@site.user}:#{ @site.password}"].pack('m').delete("\r\n") } : {})
      end

      def logger #:nodoc:
        ActiveResource::Base.logger
      end

      # Manipulate from_xml Hash, because xml_simple is not exactly what we
      # want for ActiveResource.
      def from_xml_data(data)
        if data.is_a?(Hash) && data.keys.size == 1
          data.values.first
        else
          data
        end
      end
  end
end