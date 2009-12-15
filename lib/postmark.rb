require 'net/http'
require 'net/https'
require 'rubygems'
require 'tmail'
require 'postmark/tmail_mail_extension'

module Postmark

  class InvalidApiKeyError < StandardError; end
  class UnknownError < StandardError; end
  class InvalidMessageError < StandardError; end
  class InternalServerError < StandardError; end

  module ResponseParsers
    autoload :Json,          'postmark/response_parsers/json'
    autoload :ActiveSupport, 'postmark/response_parsers/active_support'
    autoload :Yajl,          'postmark/response_parsers/yajl'
  end

  HEADERS = {
    'Content-type' => 'application/json',
    'Accept'       => 'application/json'
  }

  class << self
    attr_accessor :host, :host_path, :port, :secure, :api_key, :http_open_timeout, :http_read_timeout,
      :proxy_host, :proxy_port, :proxy_user, :proxy_pass
    attr_writer :response_parser_class

    def response_parser_class
      @response_parser_class ||= Object.const_defined?(:ActiveSupport) ? :ActiveSupport : :Json
    end

    # The port on which your Postmark server runs.
    def port
      @port || (secure ? 443 : 80)
    end

    # The host to connect to.
    def host
      @host ||= 'api.postmarkapp.com'
    end

    # The path of the listener
    def host_path
      @host_path ||= 'email'
    end

    # The HTTP open timeout (defaults to 2 seconds).
    def http_open_timeout
      @http_open_timeout ||= 5
    end

    # The HTTP read timeout (defaults to 15 seconds).
    def http_read_timeout
      @http_read_timeout ||= 15
    end

    def configure
      yield self
    end

    def protocol #:nodoc:
      secure ? "https" : "http"
    end

    def url #:nodoc:
      URI.parse("#{protocol}://#{host}:#{port}/#{host_path}/")
    end

    def send_through_postmark(message) #:nodoc:
      ResponseParsers.const_get(response_parser_class) # loads JSON lib, defining #to_json
      http = Net::HTTP::Proxy(proxy_host,
                              proxy_port,
                              proxy_user,
                              proxy_pass).new(url.host, url.port)

      http.read_timeout = http_read_timeout
      http.open_timeout = http_open_timeout
      http.use_ssl = !!secure

      headers = HEADERS.merge({ "X-Postmark-Server-Token" => api_key })

      response = http.post(url.path, convert_tmail(message).to_json, headers)

      case response.code.to_i
      when 200
        return response
      when 401
        raise InvalidApiKeyError, error_message(response.body)
      when 422
        raise InvalidMessageError, error_message(response.body)
      when 500
        raise InternalServerError, response.body
      else
        raise UnknownError, response
      end
    end

    def error_message(response_body)
      decode_json(response_body)["Message"]
    end

    def decode_json(data)
      ResponseParsers.const_get(response_parser_class).decode(data)
    end

    def encode_json(data)
      ResponseParsers.const_get(response_parser_class).encode(data)
    end

    def convert_tmail(message)
      options = { "From" => message['from'].to_s, "To" => message['to'].to_s, "Subject" => message.subject }
      html = message.body_html
      text = message.body_text
      if message.multipart?
        options["HtmlBody"] = html
        options["TextBody"] = text
      elsif html
        options["HtmlBody"] = message.body_html
      else
        options["TextBody"] = text
      end
      options
    end

  end

  self.response_parser_class = nil

end
