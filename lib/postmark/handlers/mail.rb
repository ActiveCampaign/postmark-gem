module Mail
  class Postmark

    attr_accessor :settings

    def initialize(values)
      self.settings = { :api_key => nil }.merge(values)
    end

    def deliver!(mail)
      settings = self.settings.dup
      api_key = settings.delete(:api_key)
      api_client = ::Postmark::ApiClient.new(api_key, settings)
      api_client.deliver_message(mail)
    end

  end
end