require 'enumerator'

module Postmark
  class Client
    attr_reader :http_client, :max_retries

    def initialize(api_token, options = {})
      options = options.dup
      @max_retries = options.delete(:max_retries) || 3
      @http_client = HttpClient.new(api_token, options)
    end

    def api_token=(api_token)
      http_client.api_token = api_token
    end
    alias_method :api_key=, :api_token=

    def find_each(path, name, options = {})
      if block_given?
        options = options.dup
        i, total_count = [0, 1]

        while i < total_count
          options[:offset] = i
          total_count, collection = load_batch(path, name, options)
          collection.each { |e| yield e }
          i += collection.size
        end
      else
        enum_for(:find_each, path, name, options) do
          get_resource_count(path, options)
        end
      end
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

    def get_resource_count(path, options = {})
      # At this point Postmark API returns 0 as total if you request 0 documents
      total_count, _ = load_batch(path, nil, options.merge(:count => 1))
      total_count
    end

    def load_batch(path, name, options)
      options[:offset] ||= 0
      options[:count] ||= 30
      response = http_client.get(path, options)
      [response['TotalCount'], format_response(response[name])]
    end

  end
end