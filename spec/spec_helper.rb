$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'bundler'
Bundler.setup(:development)
require 'mail'
require 'postmark'
require 'active_support'
require 'json'
require 'fakeweb'
require 'fakeweb_matcher'
require 'timecop'
require 'rspec'
require 'rspec/autorun'
require File.join(File.expand_path(File.dirname(__FILE__)), 'shared_examples.rb')

if ENV['JSONGEM']
  # `JSONGEM=Yajl rake spec`
  Postmark.response_parser_class = ENV['JSONGEM'].to_sym
  puts "Setting ResponseParser class to #{Postmark::ResponseParsers.const_get Postmark.response_parser_class}"
end

RSpec.configure do |config|
	config.filter_run_excluding :ruby => lambda { |version|
    RUBY_VERSION.to_s !~ /^#{version.to_s}/
  }
end

RSpec::Matchers.define :be_serialized_to do |json|
  match do |mail_message|
    Postmark.convert_message_to_options_hash(mail_message).should == JSON.parse(json)
  end
end
