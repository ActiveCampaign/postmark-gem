module Postmark
  class Client
    attr_reader :http_client, :max_retries

    def initialize(api_key, options = {})
      options = options.dup
      @max_retries = options.delete(:max_retries) || 3
      @http_client = HttpClient.new(api_key, options)
    end

    def api_key=(api_key)
      http_client.api_key = api_key
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

    def serialize(data)
      Postmark::Json.encode(data)
    end

    def take_response_of
      [yield, nil]
    rescue DeliveryError => e
      [e.full_response || {}, e]
    end

    def format_response(response, compatible = false)
      return {} unless response

      if response.kind_of? Array
        response.map { |entry| Postmark::HashHelper.to_ruby(entry, compatible) }
      else
        Postmark::HashHelper.to_ruby(response, compatible)
      end
    end

  end
end