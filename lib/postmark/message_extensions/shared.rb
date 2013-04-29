module Postmark
  module SharedMessageExtensions

    def self.included(klass)
      klass.instance_eval do
        attr_accessor :delivered, :postmark_response
      end
    end

    def delivered?
      self.delivered
    end

    def tag(val = nil)
      default 'TAG', val
    end

    def tag=(val)
      header['TAG'] = val
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

      Postmark::MessageHelper.attachments_to_postmark(@_attachments)
    end

    protected

    def pack_attachment_data(data)
      MessageHelper.encode_in_base64(data)
    end

  end
end
