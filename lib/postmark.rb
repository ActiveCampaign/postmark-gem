require 'net/http'
require 'net/https'

require 'postmark/bounce'
require 'postmark/json'
require 'postmark/http_client'
require 'postmark/message_extensions/shared'
require 'postmark/message_extensions/tmail'
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
    headers = extract_headers_according_to_message_format(message)

    options["From"]        = message['from'].to_s                       if message.from
    options["ReplyTo"]     = Array[message.reply_to].flatten.join(", ") if message.reply_to
    options["To"]          = message['to'].to_s                         if message.to
    options["Cc"]          = message['cc'].to_s                         if message.cc
    options["Bcc"]         = Array[message.bcc].flatten.join(", ")      if message.bcc
    options["Subject"]     = message.subject
    options["Attachments"] = message.postmark_attachments
    options["Tag"]         = message.tag.to_s                           if message.tag
    options["Headers"]     = headers                                    if headers.size > 0

    options = options.delete_if{|k,v| v.nil?}

    html = message.body_html
    text = message.body_text

    if message.multipart?
      options["HtmlBody"] = html
      options["TextBody"] = text
    elsif html
      options["HtmlBody"] = html
    else
      options["TextBody"] = text
    end

    options
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

  def extract_headers_according_to_message_format(message)
    if defined?(TMail) && message.is_a?(TMail::Mail)
      headers = extract_tmail_headers(message)
    elsif defined?(Mail) && message.kind_of?(Mail::Message)
      headers = extract_mail_headers(message)
    else
      raise "Can't convert message to a valid hash of API options. Unknown message format."
    end
  end

  def extract_mail_headers(message)
    headers = []
    message.header.fields.each do |field|
      key = field.name
      value = field.value
      next if bogus_headers.include? key.downcase
      name = key.split(/-/).map {|i| i.capitalize }.join('-')
      headers << { "Name" => name, "Value" => value }
    end
    headers
  end

  def extract_tmail_headers(message)
    headers = []
    message.each_header do |key, value|
      next if bogus_headers.include? key.downcase
      name = key.split(/-/).map {|i| i.capitalize }.join('-')
      headers << { "Name" => name, "Value" => value.body }
    end
    headers
  end

  def bogus_headers
    %q[
      return-path  x-pm-rcpt
      from         reply-to
      sender       received
      date         content-type
      cc           bcc
      subject      tag
      attachment
    ]
  end

  self.response_parser_class = nil

end
