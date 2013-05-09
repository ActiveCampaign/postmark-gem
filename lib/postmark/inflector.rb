module Postmark
  module Inflector

    extend self

    def to_postmark(name)
      name.to_s.split('_').map { |part| capitalize_first_letter(part) }.join('')
    end

    def to_ruby(name)
      name.to_s.scan(camel_case_regexp).join('_').downcase.to_sym
    end

    def camel_case_regexp
      /(?:[A-Z](?:(?:[A-Z]+(?![a-z\d]))|[a-z\d]*))|[a-z\d\_]+/
    end

    protected

    def capitalize_first_letter(str)
      if str.length > 0
        str.slice(0..0).capitalize + str.slice(1..-1)
      else
        str
      end
    end
  end
end