module Postmark
  def self.const_missing(const_name)
    replacement = Deprecations.deprecated_constants.fetch(const_name, nil) || super
    Deprecations.report("DEPRECATION WARNING: the class #{const_name} is deprecated. Use #{replacement} instead.")
    replacement
  end

  module Deprecations
    DEFAULT_BEHAVIORS = {
      :raise => lambda { |message| raise message },
      :log => lambda { |message| warn message },
      :silence => lambda { |message| },
    }

    def self.report(message)
      DEFAULT_BEHAVIORS.fetch(behavior).call(message)
    end

    def self.deprecated_constants
      @deprecated_constants ||= {}
    end

    def self.behavior
      @behavior ||= :log
    end

    def self.behavior=(behavior)
      @behavior = behavior
    end

    def self.add_constants(mappings)
      deprecated_constants.merge!(mappings)
    end
  end
end
