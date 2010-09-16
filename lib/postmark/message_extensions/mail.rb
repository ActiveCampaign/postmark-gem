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
    
    def deliver_with_postmark_hook
      remove_postmark_attachments_from_standard_fields
      deliver_without_postmark_hook
    end
    
    alias_method_chain :deliver, :postmark_hook
    
  private
  
    #
    # This is needed solely to support neat Rails 3 syntax to create emails.
    # That one:
    #
    #   def invitation
    #     mail(
    #       :to => "someone@example.com",
    #       :postmark_attachments => [File.open(...)]
    #     )
    #   end
    #
    # That code will automatically put the file to Mail::OptionalField of the Mail::Message object
    # and will try to encode it before delivery. You are not supposed to store files in
    # such fields, so Mail will raise an exception. That's why before we actually perform a
    # delivery we have to remove the files from OptionalField to a regular @_attachments variable.
    #  
    def remove_postmark_attachments_from_standard_fields
      field = self['POSTMARK-ATTACHMENTS']
      return if field.nil?
      self.postmark_attachments = field.value
      self['POSTMARK-ATTACHMENTS'] = nil
    end
    
  end
end