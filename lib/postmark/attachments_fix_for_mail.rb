module Postmark
  
  #
  # This fix is needed solely to support neat Rails 3 syntax to create emails.
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
  module AttachmentsFixForMail
    
    def self.included(base)
      base.class_eval do      
        alias_method_chain :deliver, :postmark_hook
      end
    end
    
    def deliver_with_postmark_hook
      remove_postmark_attachments_from_standard_fields
      deliver_without_postmark_hook
    end
    
  private
  
    def remove_postmark_attachments_from_standard_fields
      field = self['POSTMARK-ATTACHMENTS']
      return if field.nil?
      self.postmark_attachments = field.value
      header.fields.delete_if{|f| f.name == 'postmark-attachments'}
    end
    
  end
  
end