module Postmark
  class ApiClient
    attr_reader :http_client, :max_retries

    def initialize(api_key, options = {})
      @max_retries = options.delete(:max_retries) || 3
      @http_client = HttpClient.new(api_key, options)
    end

    def deliver_message(message)
      with_retries do
        http_client.post("email", Postmark::Json.encode(message.to_postmark_hash))
      end
    rescue Timeout::Error
      raise TimeoutError.new($!)
    end
    alias_method :send_through_postmark, :deliver_message

    def deliver_messages(messages)
      data = Postmark::Json.encode(messages.map { |m| m.to_postmark_hash })
      with_retries do
        http_client.post("email/batch", data)
      end
    rescue Timeout::Error
      raise TimeoutError.new($!)
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
      retries = retries ? retries + 1 : 0
      if retries < self.max_retries
        retry
      else
        raise
      end
    end

  end
end