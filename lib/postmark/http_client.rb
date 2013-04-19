require 'thread' unless defined? Mutex # For Ruby 1.8.7
require 'cgi'

module Postmark
  class HttpClient
    @@client_mutex = Mutex.new

    attr_reader :http, :api_key

    def self.client
      return @client if @client

      @@client_mutex.synchronize do
        @client ||= self.new(Postmark.api_key)
      end
    end

    def self.post(*args)
      client.post(*args)
    end

    def self.put(*args)
      client.put(*args)
    end

    def self.get(*args)
      client.get(*args)
    end

    def initialize(api_key)
      @api_key = api_key
      @request_mutex = Mutex.new
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

    def to_query_string(hash)
      return "" if hash.empty?
      "?" + hash.map { |key, value| "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}" }.join("&")
    end

    def protocol
      Postmark.secure ? "https" : "http"
    end

    def url
      URI.parse("#{protocol}://#{Postmark.host}:#{Postmark.port}/")
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
      @headers ||= HEADERS.merge({ "X-Postmark-Server-Token" => @api_key.to_s })
    end

    def url_path(path)
      Postmark.path_prefix + path
    end

    def do_request
      @request_mutex.synchronize do
        handle_response(yield(http))
      end
    end

    def build_http
      http = Net::HTTP::Proxy(Postmark.proxy_host,
                              Postmark.proxy_port,
                              Postmark.proxy_user,
                              Postmark.proxy_pass).new(url.host, url.port)

      http.read_timeout = Postmark.http_read_timeout
      http.open_timeout = Postmark.http_open_timeout
      http.use_ssl = !!Postmark.secure
      http
    end

    def error_message(response_body)
      Postmark::Json.decode(response_body)["Message"]
    end

    def error_message_and_code(response_body)
      reply = Postmark::Json.decode(response_body)
      [reply["Message"], reply["ErrorCode"]]
    end

    def error(clazz, response_body)
      clazz.send(:new, *error_message_and_code(response_body))
    end
  end
end
