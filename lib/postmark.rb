def require_local(file)
  require File.join(File.dirname(__FILE__), 'postmark', file)
end

require 'net/http'
require 'net/https'
# It's important to load mail before extensions.
require 'mail'
require_local 'bounce'
require_local 'json'
require_local 'http_client'
require_local 'message_extensions/shared'
require_local 'message_extensions/tmail'
require_local 'message_extensions/mail'
require 'mail/postmark'

module Postmark

  class InvalidApiKeyError < StandardError; end
  class UnknownError < StandardError; end
  class InvalidMessageError < StandardError; end
  class InternalServerError < StandardError; end
  class UnknownMessageType < StandardError; end

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
    
    def send_through_postmark(message) #:nodoc:
      @retries = 0
      begin
        HttpClient.post("email", Postmark::Json.encode(convert(message)))
      rescue Exception => e
        if @retries < max_retries
           @retries += 1
           retry
        else
          raise
        end
      end
    end
    
    def convert(message)
      if defined?(TMail) && message.is_a?(TMail::Mail)
        convert_tmail(message)
      else
        convert_mail(message)
      end
    end
    
    def delivery_stats
      HttpClient.get("deliverystats")
    end

    protected
    
    def convert_mail(message)
      options = { "From" => message.from.to_s, "Subject" => message.subject }

      headers = extract_mail_headers(message)
      options["Headers"] = headers unless headers.length == 0
      
      options["To"] = message.to.join(", ")

      options["Tag"] = message.tag.to_s unless message.tag.nil?

      options["Cc"] = message.cc.join(", ").to_s unless message.cc.nil?
      
      options["Bcc"] = message.bcc.join(", ").to_s unless message.bcc.nil?
      
      options["Attachments"] = message.postmark_attachments unless message.postmark_attachments.nil?

      if reply_to = message['reply-to']
        options["ReplyTo"] = reply_to.to_s
      end
      
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
    
    def extract_mail_headers(message)
      headers = []
      message.header.fields.each do |field|
        key = field.name
        value = field.value
        next if bogus_headers.include? key.dup.downcase
        name = key.split(/-/).map {|i| i.capitalize }.join('-')
        headers << { "Name" => name, "Value" => value }
      end
      headers
    end

    def convert_tmail(message)
      options = { "From" => message['from'].to_s, "To" => message['to'].to_s, "Subject" => message.subject }

      headers = extract_tmail_headers(message)
      options["Headers"] = headers unless headers.length == 0

      options["Tag"] = message.tag.to_s unless message.tag.nil?

      options["Cc"] = message['cc'].to_s unless message.cc.nil?

      options["Bcc"] = message['bcc'].to_s unless message.bcc.nil?
      
      options["Attachments"] = message.postmark_attachments unless message.postmark_attachments.nil?

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

    def extract_tmail_headers(message)
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
        attachment
      ]
    end

  end

  self.response_parser_class = nil

end
