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

    def export_headers
      [].tap do |headers|
        self.header.fields.each do |field|
          key, value = field.name, field.value
          next if bogus_headers.include? key.downcase
          name = key.split(/-/).map { |i| i.capitalize }.join('-')

          headers << { "Name" => name, "Value" => value }
        end
      end
    end

  protected

    def export_native_attachments
      attachments.map do |attachment|
        {"Name" => attachment.filename,
         "Content" => pack_attachment_data(attachment.body.decoded),
         "ContentType" => attachment.mime_type}
      end
    end

    def bogus_headers
      %q[
        return-path  x-pm-rcpt
        from         reply-to
        sender       received
        date         content-type
        cc           bcc
        subject      tag
        attachment
      ]
    end

  end
end