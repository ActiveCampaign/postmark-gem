module Postmark
  module RSpecHelpers
    def empty_gif_path
      File.join(File.dirname(__FILE__), '..', 'data', 'empty.gif')
    end

    def encoded_empty_gif_data
      Postmark::MessageHelper.encode_in_base64(File.read(empty_gif_path))
    end
  end
end