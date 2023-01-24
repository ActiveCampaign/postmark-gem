require 'active_support/deprecation'

module Postmark
  module Deprecations
    def self.add_constant(old, new)
      ActiveSupport::Deprecation::DeprecatedConstantProxy.new("Postmark::#{old}", "Postmark::#{new}")
    end
  end
end
