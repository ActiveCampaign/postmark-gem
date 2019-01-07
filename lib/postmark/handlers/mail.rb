module Mail
  class Postmark

    attr_accessor :settings

    def initialize(values)
      self.settings = { :api_token => ENV['POSTMARK_API_TOKEN'] }.merge(values)
    end

    def deliver!(mail)
      response = if mail.templated?
                   api_client.deliver_message_with_template(mail)
                 else
                   api_client.deliver_message(mail)
                 end

      if settings[:return_response]
        response
      else
        self
      end
    end

    def api_client
      settings = self.settings.dup
      api_token = settings.delete(:api_token) || settings.delete(:api_key)
      ::Postmark::ApiClient.new(api_token, settings)
    end
  end
end