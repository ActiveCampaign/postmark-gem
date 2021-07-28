module Postmark
  module HashHelper
    extend self

    DEFAULTS = {
      :keys_to_skip => [], # skip conversion of values for keys in the array
      :deep => false, # convert all hash keys or just top level keys
    }

    def to_postmark(hash, options = {})
      convert_hash_keys(hash, :to_postmark, options)
    end

    def to_ruby(hash, options = {})
      formatted = convert_hash_keys(hash, :to_ruby, options)
      compatibility_mode = options.fetch(:compatible, false)
      compatibility_mode ? append_compatibility_object(hash, formatted) : formatted
    end

    private

    def append_compatibility_object(hash, formatted)
      # since we use merge only on old sending endpoints, we don't need to use deep_merge! method
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

    # Hash keys will be converted ruby or postmark format. Conversion is deep by default, meaning conversion
    # is applied to all hash values if they are hashes or arrays. Specific keys to convert can be skipped.
    # This can be used when formatting of certain hash or aray needs to be preserved - like metadata value.
    def convert_hash_keys(object, conversion_type, options)
      if object.is_a? Hash
        return object.inject({}) do |m,(k,v)|
          m[Inflector.send(conversion_type, k)] =
            convert_hash_key_value?(k, options) ? convert_hash_keys(v, conversion_type, options) : v
          m
        end
      end

      return object.inject([]) { |m,v| m << convert_hash_keys(v, conversion_type, options); } if object.is_a? Array

      object
    end

    def convert_hash_key_value?(key, options)
      options = DEFAULTS.merge(options)
      return false unless options.delete(:deep)

      keys_to_skip = options.delete(:keys_to_skip).to_a
      !keys_to_skip.map { |k| k.to_s.downcase.strip }.include?(key.to_s.downcase.strip)
    end
  end
end
