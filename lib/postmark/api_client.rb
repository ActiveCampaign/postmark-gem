module Postmark
  class ApiClient
    attr_reader :http_client

    def initialize(api_key)
      @http_client = HttpClient.new(api_key)
    end

    def send_through_postmark(message)
      with_retries do
        http_client.post("email", Postmark::Json.encode(message.to_postmark_hash))
      end
    rescue Timeout::Error
      raise TimeoutError.new($!)
    end

    def delivery_stats
      http_client.get("deliverystats")
    end

    protected

    def with_retries
      yield
    rescue DeliveryError, Timeout::Error
      retries = retries ? retries + 1 : 0
      if retries < Postmark.max_retries
        retry
      else
        raise
      end
    end

  end
end