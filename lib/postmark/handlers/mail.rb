module Mail
  class Postmark

    attr_accessor :settings

    def initialize(values)
      self.settings = { :api_token => ENV['POSTMARK_API_TOKEN'] }.merge(values)
    end

    def deliver!(mail)
      server_token_index = mail.header_fields.index { |h| h.name == 'X-Postmark-Server-Token' }

      # we delete the token header from the array so that it isn't sent with the email
      server_token_from_header = server_token_index ? mail.header_fields.delete_at(server_token_index).value : nil

      response = if mail.templated?
                   api_client(server_token_from_header).deliver_message_with_template(mail)
                 else
                   api_client(server_token_from_header).deliver_message(mail)
                 end

      if settings[:return_response]
        response
      else
        self
      end
    end

    def api_client(server_token_from_header)
      settings = self.settings.dup
      api_token = server_token_from_header || settings.delete(:api_token) || settings.delete(:api_key)

      ::Postmark::ApiClient.new(api_token, settings)
    end
  end
end