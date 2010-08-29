module Mail
  class Postmark
    def initialize(values)
      self.settings = {:api_key => nil}.merge(values)
    end
    
    attr_accessor :settings
    
    def deliver!(mail)
      ::Postmark.api_key = settings[:api_key]
      ::Postmark.send_through_postmark(mail)
    end
  end
end