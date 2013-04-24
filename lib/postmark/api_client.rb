module Postmark
  class ApiClient
    attr_reader :http_client, :max_retries

    def initialize(api_key, options = {})
      @max_retries = options.delete(:max_retries) || 3
      @http_client = HttpClient.new(api_key, options)
    end

    def api_key=(api_key)
      http_client.api_key = api_key
    end

    def deliver_message(message)
      data = serialize(message.to_postmark_hash)

      with_retries do
        hold_on_errors { http_client.post("email", data) }.to do |r|
          update_message(message, r)
        end
      end
    end

    def deliver_messages(messages)
      data = serialize(messages.map { |m| m.to_postmark_hash })

      with_retries do
        http_client.post("email/batch", data).tap do |response|
          messages.each_with_index { |m, i| update_message(m, response[i]) }
        end
      end
    end

    def delivery_stats
      http_client.get("deliverystats")
    end

    def get_bounces(options = {})
      http_client.get("bounces", options)
    end

    def get_bounced_tags
      http_client.get("bounces/tags")
    end

    def get_bounce(id)
      http_client.get("bounces/#{id}")
    end

    def dump_bounce(id)
      http_client.get("bounces/#{id}/dump")
    end

    def activate_bounce(id)
      http_client.put("bounces/#{id}/activate")
    end

    protected

    def with_retries
      yield
    rescue DeliveryError
      retries = retries ? retries + 1 : 1
      if retries < self.max_retries
        retry
      else
        raise
      end
    end

    def update_message(message, response)
      response ||= {}
      message['Message-ID'] = response['MessageID']
      message.delivered = !!response['MessageID']
      message.postmark_response = response
    end

    def serialize(data)
      Postmark::Json.encode(data)
    end

    def hold_on_errors
      define_singleton_method(:to, yield)
    rescue DeliveryError => e
      define_singleton_method(:to, e.full_response || {}) do
        raise e
      end
    end

    def define_singleton_method(name, object)
      singleton_class = class << object; self; end
      singleton_class.send(:define_method, name) do |&b|
        b.call(self)
        yield if block_given?
      end
      object
    end

  end
end