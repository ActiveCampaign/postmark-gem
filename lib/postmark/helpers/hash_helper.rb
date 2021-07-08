module Postmark
  module HashHelper
    extend self

    def to_postmark(hash, options = {keys_to_skip: []})
      hash.each_with_object({}) do |(k, v), m|
        m[Inflector.to_postmark(k)] = skip_key?(k, options[:keys_to_skip]) ? v : hash_value_to_postmark(v)
      end
    end

    def to_ruby(hash, compatibility_mode = false)
      formatted = hash.each_with_object({}) { |(k, v), m| m[Inflector.to_ruby(k)] = hash_value_to_ruby(v); }
      compatibility_mode ? to_ruby_with_compatibility(hash, formatted) : formatted
    end

    private

    def skip_key?(key, keys_to_skip)
      keys_to_skip.map { |k| k.to_s.downcase.strip }.include?(key.to_s.downcase.strip)
    end

    def to_ruby_with_compatibility(hash, formatted)
      formatted.merge!(hash)
      enhance_with_compatibility_warning(formatted)
      formatted
    end

    def enhance_with_compatibility_warning(hash)
      def hash.[](key)
        if key.is_a? String
          Kernel.warn('Postmark: the CamelCased String keys of response are ' \
                      'deprecated in favor of underscored symbols. The ' \
                      'support will be dropped in the future.')
        end
        super
      end
    end

    def hash_value_to_postmark(value)
      return to_postmark(value) if value.is_a?(Hash)
      return value.map { |entry| hash_value_to_postmark(entry) } if value.is_a?(Array)

      value
    end

    def hash_value_to_ruby(value)
      return to_ruby(value) if value.is_a?(Hash)
      return value.map { |entry| hash_value_to_ruby(entry) } if value.is_a?(Array)

      value
    end
  end
end
