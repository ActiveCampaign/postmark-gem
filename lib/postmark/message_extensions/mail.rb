module Mail
  class Message
    def html?
      content_type && content_type.include?('text/html')
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

    def tag
      self['TAG']
    end

    def tag=(value)
      self['TAG'] = value
    end

    def postmark_attachments=(value)
      @_attachments = value.is_a?(Array) ? value : [value]
    end

    def postmark_attachments
      return if @_attachments.nil?

      @_attachments.collect do |item|
        if item.is_a?(Hash)
          item
        elsif item.is_a?(File)
          {
            "Name"        => item.path.split("/")[-1],
            "Content"     => [ IO.read(item.path) ].pack("m"),
            "ContentType" => "application/octet-stream"
          }
        end
      end
    end


  end
end
