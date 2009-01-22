require 'net/https'
require 'date'
require 'time'
require 'uri'
require 'cgi'
require 'benchmark'

module Net
  class HTTPNoResponse < HTTPResponse
    HAS_BODY = false
    EXCEPTION_TYPE = HTTPRetriableError
    def body
      {:status => 'T', :term_code => '30000', :description => 'Could not reach the remote site.'}.to_xml
    end
  end
end

module GotoBilling
  class ConnectionError < StandardError # :nodoc:
    attr_reader :response

    def initialize(response, message = nil)
      @response = response
      @message  = message
    end

    def to_s
      "Failed with #{response.code} #{response.message if response.respond_to?(:message)}"
    end
  end

  # 3xx Redirection
  class Redirection < ConnectionError # :nodoc:
    def to_s; response['Location'] ? "#{super} => #{response['Location']}" : super; end
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
  # This class is used by GotoBilling::Base to interface with REST
  # services.
  class Connection
    attr_reader :site
    attr_accessor :format

    class << self
      def requests
        @@requests ||= []
      end
    end

    # The +site+ parameter is required and will set the +site+
    # attribute to the URI for the remote resource service.
    def initialize(site, ip_address, format = ActiveResource::Formats[:xml])
      raise ArgumentError, 'Missing site URI' unless site
      @site = site
      @ip_address = ip_address
      self.format = format
    end

    # Execute a GET request.
    # Used to get (find) resources.
    def get(path, data={}, headers = {})
      format.decode(
        request(:get,
          path + '?' + data.update('ip_address' => @ip_address).to_query,
          build_request_headers(headers)
        ).body
      )
    end

    # Execute a POST request.
    # Used to create new resources.
    def post(path, data={}, headers = {})
      format.decode(
        request(:post,
          path,
          data.update('ip_address' => @ip_address).map {|k,v| "#{urlencode(k.to_s)}=#{urlencode(v.to_s)}" }.join('&'),
          build_request_headers(headers.update('Content-Type' => 'application/x-www-form-urlencoded'))
        ).body
      )
    end

    private
      def urlencode(str)
        str.gsub(/[^a-zA-Z0-9_\.\-]/n) {|s| sprintf('%%%02x', s[0]) }
      end

      # Makes request to remote service.
      def request(method, path, *arguments)
        puts "#{method.to_s.upcase} #{site.scheme}://#{site.host}:#{site.port}#{path}"
        result = nil
        time = Benchmark.realtime {
          result = Net::HTTPNoResponse.new('1.1', 399, 'Could not complete the HTTP Request')
          begin
            result = http.send(method, path, *arguments)
          rescue TimeoutError
          rescue SocketError
          rescue Errno::ETIMEDOUT
          rescue Timeout::Error
          rescue Errno::EHOSTDOWN
          end
        }
        puts "--> #{result.code} #{result.message} (#{result.body.length}b %.2fs)" % time
        handle_response(result)
      end

      # Handles response and error codes from remote service.
      def handle_response(response)
        case response.code.to_i
          when 301,302
            raise(Redirection.new(response))
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
        @http
      end

      def default_header
        @default_header ||= { 'Content-Type' => format.mime_type }
      end
      
      # Builds headers for request to remote service.
      def build_request_headers(headers)
        authorization_header.update(default_header).update(headers)
      end
      
      # Sets authorization header; authentication information is pulled from credentials provided with site URI.
      def authorization_header
        (@site.user || @site.password ? { 'Authorization' => 'Basic ' + ["#{@site.user}:#{ @site.password}"].pack('m').delete("\r\n") } : {})
      end

  end
end