require 'net/http'
require 'net/https'

require 'postmark/inflector'
require 'postmark/bounce'
require 'postmark/json'
require 'postmark/http_client'
require 'postmark/message_extensions/shared'
require 'postmark/message_extensions/mail'
require 'postmark/handlers/mail'
require 'postmark/attachments_fix_for_mail'

module Postmark

  class DeliveryError < StandardError
    attr_accessor :error_code

    def initialize(message = nil, error_code = nil)
      super(message)
      self.error_code = error_code
    end
  end

  class UnknownError        < DeliveryError; end
  class InvalidApiKeyError  < DeliveryError; end
  class InvalidMessageError < DeliveryError; end
  class InternalServerError < DeliveryError; end
  class UnknownMessageType  < DeliveryError; end
  class TimeoutError        < DeliveryError; end

  module ResponseParsers
    autoload :Json,          'postmark/response_parsers/json'
    autoload :ActiveSupport, 'postmark/response_parsers/active_support'
    autoload :Yajl,          'postmark/response_parsers/yajl'
  end

  HEADERS = {
    'Content-type' => 'application/json',
    'Accept'       => 'application/json'
  }

  extend self

  attr_accessor :host, :path_prefix, :port, :secure, :api_key, :http_open_timeout, :http_read_timeout,
    :proxy_host, :proxy_port, :proxy_user, :proxy_pass, :max_retries, :sleep_between_retries

  attr_writer :response_parser_class

  def response_parser_class
    @response_parser_class ||= defined?(ActiveSupport::JSON) ? :ActiveSupport : :Json
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

  def send_through_postmark(message) #:nodoc:
    with_retries do
      HttpClient.post("email", Postmark::Json.encode(convert_message_to_options_hash(message)))
    end
  rescue Timeout::Error
    raise TimeoutError.new($!)
  end

  def convert_message_to_options_hash(message)
    options = Hash.new
    headers = message.export_headers
    attachments = message.export_attachments

    options["From"] = message['from'].to_s if message.from
    options["Subject"] = message.subject
    options["Attachments"] = attachments unless attachments.empty?
    options["Headers"] = headers if headers.size > 0
    options["HtmlBody"] = message.body_html
    options["TextBody"] = message.body_text
    options["Tag"] = message.tag.to_s if message.tag

    %w(to reply_to cc bcc).each do |field|
      next unless value = message.send(field)
      options[Inflector.to_postmark(field)] = Array[value].flatten.join(", ")
    end

    options.delete_if { |k,v| v.nil? }
  end

  def delivery_stats
    HttpClient.get("deliverystats")
  end

  protected

  def with_retries
    yield
  rescue DeliveryError, Timeout::Error
    retries = retries ? retries + 1 : 0
    if retries < max_retries
      retry
    else
      raise
    end
  end

  self.response_parser_class = nil

end
