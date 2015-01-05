require 'net/http'
require 'net/https'
require 'thread' unless defined? Mutex # For Ruby 1.8.7

require 'postmark/version'
require 'postmark/inflector'
require 'postmark/helpers/hash_helper'
require 'postmark/helpers/message_helper'
require 'postmark/mail_message_converter'
require 'postmark/bounce'
require 'postmark/inbound'
require 'postmark/json'
require 'postmark/http_client'
require 'postmark/client'
require 'postmark/api_client'
require 'postmark/account_api_client'
require 'postmark/message_extensions/mail'
require 'postmark/handlers/mail'

module Postmark

  class DeliveryError < StandardError
    attr_accessor :error_code, :full_response

    def initialize(message = nil, error_code = nil, full_response = nil)
      super(message)
      self.error_code = error_code
      self.full_response = full_response
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
    'User-Agent'   => "Postmark Ruby Gem v#{VERSION}",
    'Content-type' => 'application/json',
    'Accept'       => 'application/json'
  }

  extend self

  @@api_client_mutex = Mutex.new

  attr_accessor :secure, :api_token, :proxy_host, :proxy_port, :proxy_user,
                :proxy_pass, :host, :port, :path_prefix,
                :http_open_timeout, :http_read_timeout, :max_retries

  alias_method :api_key, :api_token
  alias_method :api_key=, :api_token=

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
                        self.api_token,
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

  def deliver_message(*args)
    api_client.deliver_message(*args)
  end
  alias_method :send_through_postmark, :deliver_message

  def deliver_messages(*args)
    api_client.deliver_messages(*args)
  end

  def delivery_stats(*args)
    api_client.delivery_stats(*args)
  end

end

Postmark.response_parser_class = nil