module Postmark
  module HashHelper

    extend self

    def to_postmark(hash)
      hash.inject({}) { |m, (k,v)| m[Inflector.to_postmark(k)] = v; m }
    end

    def to_ruby(hash, compatible = false)
      formatted = hash.inject({}) { |m, (k,v)| m[Inflector.to_ruby(k)] = v; m }

      if compatible
        formatted.merge!(hash)
        enhance_with_compatibility_warning(formatted)
      end

      formatted
    end

    protected

    def enhance_with_compatibility_warning(hash)
      def hash.[](key)
        if key.is_a? String
          Kernel.warn("Postmark: the CamelCased String keys of response are " \
                      "deprecated in favor of underscored symbols. The " \
                      "support will be dropped in the future.")
        end
        super
      end
    end

  end
end