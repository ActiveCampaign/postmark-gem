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

  MAX_RETRIES = 2

  class << self
    attr_accessor :host, :path_prefix, :port, :secure, :api_key, :http_open_timeout, :http_read_timeout,
      :proxy_host, :proxy_port, :proxy_user, :proxy_pass, :max_retries, :sleep_between_retries

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
    def path_prefix
      @path_prefix ||= '/'
    end

    def http_open_timeout
      @http_open_timeout ||= 5
    end

    def http_read_timeout
      @http_read_timeout ||= 15
    end

    def max_retries
      @max_retries ||= 3
    end

    def sleep_between_retries
      @sleep_between_retries ||= 10
    end

    def configure
      yield self
    end

    def protocol #:nodoc:
      secure ? "https" : "http"
    end

    def url #:nodoc:
      URI.parse("#{protocol}://#{host}:#{port}/")
    end

    def send_through_postmark(message) #:nodoc:
      @retries = 0
      begin
        post("email", encode_json(convert_tmail(message)))
      rescue Exception => e
        if @retries < max_retries
           @retries += 1
           retry
        else
          raise
        end
      end
    end

    def delivery_stats
      get("deliverystats")
    end

    protected

    def post(path, data)
      handle_response(http.post(url_path(path), data, headers))
    end

    def get(path)
      handle_response(http.get(url_path(path), headers))
    end

    def handle_response(response)
      case response.code.to_i
      when 200
        return decode_json(response.body)
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

    def headers
      @headers ||= HEADERS.merge({ "X-Postmark-Server-Token" => api_key.to_s })
    end

    def url_path(path)
      File.join(path_prefix, path, "/")
    end

    def http
      @http ||= build_http
    end

    def build_http
      http = Net::HTTP::Proxy(proxy_host,
                              proxy_port,
                              proxy_user,
                              proxy_pass).new(url.host, url.port)

      http.read_timeout = http_read_timeout
      http.open_timeout = http_open_timeout
      http.use_ssl = !!secure
      http
    end

    def error_message(response_body)
      decode_json(response_body)["Message"]
    end

    def decode_json(data)
      json_parser.decode(data)
    end

    def encode_json(data)
      json_parser
      data.to_json
    end

    def json_parser
      ResponseParsers.const_get(response_parser_class)
    end

    def convert_tmail(message)
      options = { "From" => message['from'].to_s, "To" => message['to'].to_s, "Subject" => message.subject }

      headers = extract_headers(message)
      options["Headers"] = headers unless headers.length == 0

      options["Tag"] = message.tag.to_s unless message.tag.nil?

      options["Cc"] = message['cc'].to_s unless message.cc.nil?

      if reply_to = message['reply-to']
        options["ReplyTo"] = reply_to.to_s
      end

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

    def extract_headers(message)
      headers = []
      message.each_header do |key, value|
        next if bogus_headers.include? key.dup.downcase
        name = key.split(/-/).map {|i| i.capitalize }.join('-')
        headers << { "Name" => name, "Value" => value.body }
      end
      headers
    end

    def bogus_headers
      %q[
        return-path
        x-pm-rcpt
        from
        reply-to
        sender
        received
        date
        content-type
        cc
        bcc
        subject
        tag
      ]
    end

  end

  self.response_parser_class = nil

end
