$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'mail'
require 'postmark'
require 'active_support'
require 'json'
require 'fakeweb'
require 'fakeweb_matcher'
require 'timecop'

if ENV['JSONGEM']
  # `JSONGEM=Yajl rake spec`
  Postmark.response_parser_class = ENV['JSONGEM'].to_sym
  puts "Setting ResponseParser class to #{Postmark::ResponseParsers.const_get Postmark.response_parser_class}"
end

RSpec::Matchers.define :be_serialized_to do |json|
  match do |message|
    Postmark.send(:convert_message_to_options_hash, message) == JSON.parse(json)
  end
  failure_message_for_should do |actual|
    "expected that #{actual.inspect} would be serialized to #{json.inspect}"
  end
end
