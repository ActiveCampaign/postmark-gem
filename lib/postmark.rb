require 'net/http'
require 'net/https'
require 'thread' unless defined? Mutex # For Ruby 1.8.7

require 'postmark/inflector'
require 'postmark/bounce'
require 'postmark/json'
require 'postmark/http_client'
require 'postmark/api_client'
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

  @@api_client_mutex = Mutex.new

  attr_accessor :secure, :api_key, :proxy_host, :proxy_port, :proxy_user,
                :proxy_pass, :host, :port, :path_prefix,
                :http_open_timeout, :http_read_timeout, :max_retries

  attr_writer :response_parser_class, :api_client

  def response_parser_class
    @response_parser_class ||= defined?(ActiveSupport::JSON) ? :ActiveSupport : :Json
  end

  def configure
    yield self
  end

  def api_client
    return @api_client if @api_client

    @@api_client_mutex.synchronize do
      @api_client ||= Postmark::ApiClient.new(
                        self.api_key,
                        :secure => self.secure,
                        :proxy_host => self.proxy_host,
                        :proxy_port => self.proxy_port,
                        :proxy_user => self.proxy_user,
                        :proxy_pass => self.proxy_pass,
                        :host => self.host,
                        :port => self.port,
                        :path_prefix => self.path_prefix,
                        :max_retries => self.max_retries
                      )
    end
  end

  def send_through_postmark(*args)
    api_client.send_through_postmark(*args)
  end

  def delivery_stats(*args)
    api_client.delivery_stats(*args)
  end

end

Postmark.response_parser_class = nil