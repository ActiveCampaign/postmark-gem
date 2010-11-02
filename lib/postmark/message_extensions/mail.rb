module Mail
  class Message
    
    include Postmark::SharedMessageExtensions
    
    def html?
      content_type.include?('text/html')
    end
    
    def body_html
      if html_part.nil?
        body.to_s if html?
      else
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