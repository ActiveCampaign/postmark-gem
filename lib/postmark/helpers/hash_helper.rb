module Postmark
  module HashHelper

    extend self

    def to_postmark(hash)
      hash.inject({}) { |memo, (k,v)| memo[Inflector.to_postmark(k)] = v; memo }
    end

    def to_ruby(hash)
      hash.inject({}) { |memo, (k,v)| memo[Inflector.to_ruby(k)] = v; memo }
    end

  end
end