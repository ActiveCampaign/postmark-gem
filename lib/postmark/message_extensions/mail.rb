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
        body.to_s unless html?
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

    def to_postmark_hash
      options = Hash.new
      headers = self.export_headers
      attachments = self.export_attachments

      options["From"] = self['from'].to_s if self.from
      options["Subject"] = self.subject
      options["Attachments"] = attachments unless attachments.empty?
      options["Headers"] = headers if headers.size > 0
      options["HtmlBody"] = self.body_html
      options["TextBody"] = self.body_text
      options["Tag"] = self.tag.to_s if self.tag

      %w(to reply_to cc bcc).each do |field|
        next unless self.send(field)
        value = self[field.to_s]
        options[::Postmark::Inflector.to_postmark(field)] = Array[value].flatten.join(", ")
      end

      options.delete_if { |k,v| v.nil? || v.empty? }
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