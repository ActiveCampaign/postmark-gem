module Mail
  class Message
    def tag
      self["TAG"]
    end

    def tag=(value)
      self["TAG"] = value
    end
    
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