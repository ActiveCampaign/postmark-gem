module Mail
  class Message

    attr_accessor :delivered, :postmark_response

    def delivered?
      self.delivered
    end

    def tag(val = nil)
      default 'TAG', val
    end

    def tag=(val)
      header['TAG'] = val
    end

    def track_links(val = nil)
      self.track_links=(val) unless val.nil?
      header['TRACK-LINKS'].to_s
    end

    def track_links=(val)
      header['TRACK-LINKS'] = ::Postmark::Inflector.to_postmark(val)
    end

    def track_opens(val = nil)
      self.track_opens=(val) unless val.nil?
      header['TRACK-OPENS'].to_s
    end

    def track_opens=(val)
      header['TRACK-OPENS'] = (!!val).to_s
    end

    def postmark_attachments=(value)
      Kernel.warn("Mail::Message#postmark_attachments= is deprecated and will " \
                  "be removed in the future. Please consider using the native " \
                  "attachments API provided by Mail library.")
      @_attachments = value
    end

    def postmark_attachments
      return [] if @_attachments.nil?
      Kernel.warn("Mail::Message#postmark_attachments is deprecated and will " \
                  "be removed in the future. Please consider using the native " \
                  "attachments API provided by Mail library.")

      ::Postmark::MessageHelper.attachments_to_postmark(@_attachments)
    end

    def text?
      if defined?(super)
        super
      else
        has_content_type? ? !!(main_type =~ /^text$/i) : false
      end
    end

    def html?
      text? && !!(sub_type =~ /^html$/i)
    end

    def body_html
      if multipart? && html_part
        html_part.decoded
      elsif html?
        decoded
      end
    end

    def body_text
      if multipart? && text_part
        text_part.decoded
      elsif text? && !html?
        decoded
      elsif !html?
        body.decoded
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
      ready_to_send!
      ::Postmark::MailMessageConverter.new(self).run
    end

  protected

    def pack_attachment_data(data)
      ::Postmark::MessageHelper.encode_in_base64(data)
    end

    def export_native_attachments
      attachments.map do |attachment|
        basics = {"Name" => attachment.filename,
                  "Content" => pack_attachment_data(attachment.body.decoded),
                  "ContentType" => attachment.mime_type}
        specials = attachment.inline? ? {'ContentID' => attachment.url} : {}

        basics.update(specials)
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
        attachment   to
        track-opens  track-links
      ]
    end

  end
end
