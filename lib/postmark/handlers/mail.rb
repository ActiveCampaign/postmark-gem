module Mail
  class Postmark

    attr_accessor :settings

    def initialize(values)
      self.settings = { :api_token => ENV['POSTMARK_API_TOKEN'] }.merge(values)
    end

    def deliver!(mail)
      settings = self.settings.dup
      api_token = settings.delete(:api_token) || settings.delete(:api_key)
      api_client = ::Postmark::ApiClient.new(api_token, settings)
      response = api_client.deliver_message(mail)

      if settings[:return_response]
        response
      else
        self
      end
    end

  end
end