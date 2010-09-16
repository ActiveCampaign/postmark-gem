module Mail
  class Message
    
    include Postmark::SharedMessageExtensions
    
    def body_html
      unless html_part.nil?
        html_part.body.to_s
      end
    end

    def body_text
      if text_part.nil?
        body.to_s
      else
        text_part.body.to_s
      end
    end
    
  end
end