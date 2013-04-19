module Postmark
  module Inflector

    extend self

    def to_postmark(name)
      name.split('_').map { |part| part.capitalize }.join('')
    end

    def to_ruby(name)
      name.scan(/[A-Z][a-z]+/).join('_').downcase
    end
  end
end