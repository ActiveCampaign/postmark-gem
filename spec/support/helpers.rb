module Postmark
  module RSpecHelpers
    def empty_gif_path
      File.join(File.dirname(__FILE__), '..', 'data', 'empty.gif')
    end
  end
end