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

    def metadata(val = nil)
      if val
        @metadata = val
      else
        @metadata ||= {}
      end
    end

    def metadata=(val)
      @metadata = val
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

    def template_alias(val = nil)
      return self[:postmark_template_alias] && self[:postmark_template_alias].to_s if val.nil?
      self[:postmark_template_alias] = val
    end

    attr_writer :template_model
    def template_model(model = nil)
      return @template_model if model.nil?
      @template_model = model
    end

    def message_stream(val = nil)
      self.message_stream = val unless val.nil?
      header['MESSAGE-STREAM'].to_s
    end

    def message_stream=(val)
      header['MESSAGE-STREAM'] = val
    end

    def templated?
      !!template_alias
    end

    def prerender
      raise ::Postmark::Error, 'Cannot prerender a message without an associated template alias' unless templated?

      unless delivery_method.is_a?(::Mail::Postmark)
        raise ::Postmark::MailAdapterError, "Cannot render templates via #{delivery_method.class} adapter."
      end

      client = delivery_method.api_client
      template = client.get_template(template_alias)
      response = client.validate_template(template.merge(:test_render_model => template_model || {}))

      raise ::Postmark::InvalidTemplateError, response unless response[:all_content_is_valid]

      self.body = nil

      subject response[:subject][:rendered_content]

      text_part do
        body response[:text_body][:rendered_content]
      end

      html_part do
        content_type 'text/html; charset=UTF-8'
        body response[:html_body][:rendered_content]
      end

      self
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
          next if reserved_headers.include? key.downcase
          headers << { "Name" => key, "Value" => value }
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
        {
          "Name" => attachment.filename,
          "Content" => pack_attachment_data(attachment.body.decoded),
          "ContentType" => attachment.content_type,
          "ContentID" => attachment.inline? ? attachment.url : nil
        }.delete_if { |_k, v| v.nil? }
      end
    end

    def reserved_headers
      %q[
        return-path  x-pm-rcpt
        from         reply-to
        sender       received
        date         content-type
        cc           bcc
        subject      tag
        attachment   to
        track-opens  track-links
        postmark-template-alias
        message-stream
      ]
    end

  end
end
