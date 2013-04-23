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
      with_retries do
        http_client.post("email", serialize(message.to_postmark_hash))
      end
    end

    def deliver_messages(messages)
      data = serialize(messages.map { |m| m.to_postmark_hash })

      with_retries do
        http_client.post("email/batch", data)
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
    rescue DeliveryError, Timeout::Error
      retries = retries ? retries + 1 : 1
      if retries < self.max_retries
        retry
      else
        raise
      end
    end

    def serialize(data)
      Postmark::Json.encode(data)
    end

  end
end