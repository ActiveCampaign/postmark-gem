module Postmark
  module HashHelper

    extend self

    def to_postmark(hash)
      hash.inject({}) { |m, (k,v)| m[Inflector.to_postmark(k)] = object_value_to_postmark(v); m }
    end

    def to_ruby(hash, compatible = false)
      formatted = hash.inject({}) { |m, (k,v)| m[Inflector.to_ruby(k)] = object_value_to_ruby(v); m }

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

    private

    def object_value_to_postmark(value)
      return to_postmark(value) if value.is_a?(Hash)
      return value.map { |entry| to_postmark(entry) } if value.is_a?(Array)

      value
    end

    def object_value_to_ruby(value)
      return to_ruby(value) if value.is_a?(Hash)
      return value.map { |entry| to_ruby(entry) } if value.is_a?(Array)

      value
    end
  end
end