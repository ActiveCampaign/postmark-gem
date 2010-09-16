module Mail
  class Postmark
    
    attr_accessor :settings
    
    def initialize(values)
      self.settings = { :api_key => nil }.merge(values)
    end
    
    def deliver!(mail)
      ::Postmark.api_key = settings[:api_key]
      ::Postmark.send_through_postmark(mail)
    end
    
  end
end