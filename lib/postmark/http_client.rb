require 'thread' unless defined? Mutex # For Ruby 1.8.7
require 'cgi'

module Postmark
  class HttpClient
    attr_accessor :api_key
    attr_reader :http, :secure, :proxy_host, :proxy_port, :proxy_user,
                :proxy_pass, :host, :port, :path_prefix,
                :http_open_timeout, :http_read_timeout

    DEFAULTS = {
      :host => 'api.postmarkapp.com',
      :secure => false,
      :path_prefix => '/',
      :http_read_timeout => 15,
      :http_open_timeout => 5
    }

    def initialize(api_key, options = {})
      @api_key = api_key
      @request_mutex = Mutex.new
      apply_options(options)
      @http = build_http
    end

    def post(path, data = '')
      do_request { |client| client.post(url_path(path), data, headers) }
    end

    def put(path, data = '')
      do_request { |client| client.put(url_path(path), data, headers) }
    end

    def get(path, query = {})
      do_request { |client| client.get(url_path(path + to_query_string(query)), headers) }
    end

    protected

    def apply_options(options = {})
      options = Hash[*options.select { |_, v| !v.nil? }.flatten]
      DEFAULTS.merge(options).each_pair do |name, value|
        instance_variable_set(:"@#{name}", value)
      end
      @port = options[:port] || @secure ? 443 : 80
    end

    def to_query_string(hash)
      return "" if hash.empty?
      "?" + hash.map { |key, value| "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}" }.join("&")
    end

    def protocol
      self.secure ? "https" : "http"
    end

    def url
      URI.parse("#{protocol}://#{self.host}:#{self.port}/")
    end

    def handle_response(response)
      case response.code.to_i
      when 200
        return Postmark::Json.decode(response.body)
      when 401
        raise error(InvalidApiKeyError, response.body)
      when 422
        raise error(InvalidMessageError, response.body)
      when 500
        raise error(InternalServerError, response.body)
      else
        raise UnknownError, response
      end
    end

    def headers
      HEADERS.merge({ "X-Postmark-Server-Token" => self.api_key.to_s })
    end

    def url_path(path)
      self.path_prefix + path
    end

    def do_request
      @request_mutex.synchronize do
        handle_response(yield(http))
      end
    rescue Timeout::Error
      raise TimeoutError.new($!)
    end

    def build_http
      http = Net::HTTP::Proxy(self.proxy_host,
                              self.proxy_port,
                              self.proxy_user,
                              self.proxy_pass).new(url.host, url.port)

      http.read_timeout = self.http_read_timeout
      http.open_timeout = self.http_open_timeout
      http.use_ssl = !!self.secure
      http
    end

    def error_message(response_body)
      Postmark::Json.decode(response_body)["Message"]
    end

    def error_message_and_code(response_body)
      reply = Postmark::Json.decode(response_body)
      [reply["Message"], reply["ErrorCode"], reply]
    end

    def error(clazz, response_body)
      clazz.send(:new, *error_message_and_code(response_body))
    end
  end
end
