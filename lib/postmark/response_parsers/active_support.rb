# assume activesupport is already loaded
module Postmark
  module ResponseParsers
    module ActiveSupport
      def self.decode(data)
        ::ActiveSupport::JSON.decode(data)
      end
    end
  end
end
