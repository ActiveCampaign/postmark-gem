RSpec::Matchers.define :a_postmark_json do |string|
  def postmark_key?(key)
    key == ::Postmark::Inflector.to_postmark(key)
  end

  def postmark_object?(obj)
    case obj
    when Hash
      return false unless obj.keys.all? { |k| postmark_key?(k) }
      return false unless obj.values.all? { |v| postmark_object?(v) }
    when Array
      return false unless obj.all? { |v| postmark_object?(v) }
    end

    true
  end

  def postmark_json?(str)
    return false unless str.is_a?(String)

    json = Postmark::Json.decode(str)
    postmark_object?(json)
  rescue
    false
  end

  match do |actual|
    postmark_json?(actual)
  end
end

RSpec::Matchers.define :json_representation_of do |x|
  match { |actual| Postmark::Json.decode(actual) == x }
end
