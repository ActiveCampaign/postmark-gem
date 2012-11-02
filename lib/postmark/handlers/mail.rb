module Mail
  class Postmark

    attr_accessor :settings

    def initialize(values)
      self.settings = { :api_key => nil }.merge(values)
    end

    def deliver!(mail)
      ::Postmark.api_key = settings[:api_key]
      response = ::Postmark.send_through_postmark(mail)
      mail["Message-ID"] = response["MessageID"] if response.kind_of?(Hash)
    end

  end
end