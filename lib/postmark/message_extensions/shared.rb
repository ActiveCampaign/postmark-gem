module Postmark
  module SharedMessageExtensions

    def tag
      self['TAG']
    end

    def tag=(value)
      self['TAG'] = value
    end

    def postmark_attachments=(value)
      Kernel.warn("Mail::Message#postmark_attachments= is deprecated and will " \
                  "be removed in the future. Please consider using the native " \
                  "attachments API provided by Mail library.")
      @_attachments = wrap_in_array(value)
    end

    def postmark_attachments
      Kernel.warn("Mail::Message#postmark_attachments is deprecated and will " \
                  "be removed in the future. Please consider using the native " \
                  "attachments API provided by Mail library.")
      return [] if @_attachments.nil?

      @_attachments.map do |item|
        if item.is_a?(Hash)
          item
        elsif item.is_a?(File)
          {
            "Name"        => item.path.split("/")[-1],
            "Content"     => pack_attachment_data(IO.read(item.path)),
            "ContentType" => "application/octet-stream"
          }
        end
      end
    end

    protected

    def pack_attachment_data(data)
      [data].pack('m')
    end

    # From ActiveSupport (Array#wrap)
    def wrap_in_array(object)
      if object.nil?
        []
      elsif object.respond_to?(:to_ary)
        object.to_ary || [object]
      else
        [object]
      end
    end

  end
end
