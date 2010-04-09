module Postmark
  module Json

    class << self
      def encode(data)
        json_parser
        data.to_json
      end

      def decode(data)
        json_parser.decode(data)
      end

      private

      def json_parser
        ResponseParsers.const_get(Postmark.response_parser_class)
      end

    end
  end
end
