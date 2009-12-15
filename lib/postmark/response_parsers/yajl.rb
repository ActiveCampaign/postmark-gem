require 'yajl'
Yajl::Encoder.enable_json_gem_compatability
module Postmark
  module ResponseParsers
    module Yajl
      def self.decode(data)
        ::Yajl::Parser.parse(data)
      end
    end
  end
end