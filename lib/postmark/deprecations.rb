require 'active_support/deprecation'

module Postmark
  module Deprecations
    Deprecator = ActiveSupport::Deprecation.new('2.0', 'Postmark')

    def self.behavior=(behavior)
      Deprecator.behavior = behavior
    end

    def self.behavior
      Deprecator.behavior
    end

    def self.add_constant(old:, new:)
      ActiveSupport::Deprecation::DeprecatedConstantProxy.new("Postmark::#{old}", "Postmark::#{new}", Deprecator)
    end
  end
end
