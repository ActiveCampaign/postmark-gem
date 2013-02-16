module Mail
  class Message
    
    include Postmark::SharedMessageExtensions
    
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

    def export_attachments
      export_native_attachments + postmark_attachments
    end

  protected

    def export_native_attachments
      attachments.map do |attachment|
        {"Name" => attachment.filename,
         "Content" => pack_attachment_data(attachment.body.decoded),
         "ContentType" => attachment.mime_type}
      end
    end
    
  end
end