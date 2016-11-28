module Postmark

  class MailMessageConverter

    def initialize(message)
      @message = message
    end

    def run
      delete_blank_fields(convert)
    end

    protected

    def convert
      headers_part.merge(content_part)
    end

    def delete_blank_fields(message_hash)
      message_hash.delete_if { |k, v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }
    end

    def headers_part
      {
        'From' => @message['from'].to_s,
        'To' => @message['to'].to_s,
        'ReplyTo' => @message['reply_to'].to_s,
        'Cc' => @message['cc'].to_s,
        'Bcc' => @message['bcc'].to_s,
        'Subject' => @message.subject,
        'Headers' => @message.export_headers,
        'Tag' => @message.tag.to_s,
        'TrackOpens' => (cast_to_bool(@message.track_opens) unless @message.track_opens.empty?),
        'TrackLinks' => (@message.track_links unless @message.track_links.empty?)
      }
    end

    def content_part
      {
        'Attachments' => @message.export_attachments,
        'HtmlBody' => @message.body_html,
        'TextBody' => @message.body_text
      }
    end

    protected

    def cast_to_bool(val)
      if val.is_a?(TrueClass) || val.is_a?(FalseClass)
        val
      elsif val.is_a?(String) && val.downcase == "true"
        true
      else
        false
      end
    end

  end

end