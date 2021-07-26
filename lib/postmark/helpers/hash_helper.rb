module Postmark
  module HashHelper

    extend self

    def to_postmark(object, options = {})
      deep = options.fetch(:deep, false)

      case object
      when Hash
        object.reduce({}) do |m, (k, v)|
          m.tap do |h|
            h[Inflector.to_postmark(k)] = deep ? to_postmark(v, options) : v
          end
        end
      when Array
        deep ? object.map { |v| to_postmark(v, options) } : object
      else
        object
      end
    end

    def to_ruby(object, options = {})
      compatible = options.fetch(:compatible, false)
      deep = options.fetch(:deep, false)

      case object
      when Hash
        object.reduce({}) do |m, (k, v)|
          m.tap do |h|
            h[Inflector.to_ruby(k)] = deep ? to_ruby(v, options) : v
          end
        end.tap do |result|
          if compatible
            result.merge!(object)
            enhance_with_compatibility_warning(result)
          end
        end
      when Array
        deep ? object.map { |v| to_ruby(v, options) } : object
      else
        object
      end
    end

    private

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