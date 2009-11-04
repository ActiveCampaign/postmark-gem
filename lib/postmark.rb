require 'net/http'
require 'net/https'
require 'rubygems'
require 'active_support'
require 'tmail'
require 'json'
require 'postmark/tmail_mail_extension'

module Postmark

  class InvalidApiKeyError < StandardError; end 
  class UnknownError < StandardError; end
  class InvalidMessageError < StandardError; end
  class InternalServerError < StandardError; end

  HEADERS = {
    'Content-type' => 'application/json',
    'Accept'       => 'application/json'
  }

  class << self
    attr_accessor :host, :host_path, :port, :secure, :api_key, :http_open_timeout, :http_read_timeout,
      :proxy_host, :proxy_port, :proxy_user, :proxy_pass

    # The port on which your Postmark server runs.
    def port
      @port || (secure ? 443 : 80)
    end

    # The host to connect to.
    def host
      @host ||= 'postmarkapp.com'
    end

    # The path of the listener
    def host_path
      @host_path ||= 'email'
    end

    # The HTTP open timeout (defaults to 2 seconds).
    def http_open_timeout
      @http_open_timeout ||= 2
    end

    # The HTTP read timeout (defaults to 5 seconds).
    def http_read_timeout
      @http_read_timeout ||= 5
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
      JSON.parse(response_body)["Message"]
    end

    def convert_tmail(message)
      { "From" => message['from'].to_s, "To" => message['to'].to_s, "Subject" => message.subject }.tap do |hash|
        if html = message.body_html
          hash["HtmlBody"] = html
        else
          hash["TextBody"] = message.body
        end
      end
    end

  end

end
