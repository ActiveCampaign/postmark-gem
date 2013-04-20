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
require File.join(File.expand_path(File.dirname(__FILE__)), 'support', 'shared_examples.rb')

if ENV['JSONGEM']
  # `JSONGEM=Yajl rake spec`
  Postmark.response_parser_class = ENV['JSONGEM'].to_sym
  puts "Setting ResponseParser class to #{Postmark::ResponseParsers.const_get Postmark.response_parser_class}"
end

RSpec.configure do |config|
	config.filter_run_excluding :ruby => lambda { |version|
    RUBY_VERSION.to_s !~ /^#{version.to_s}/
  }

  config.before(:each) do
    %w(api_client response_parser_class secure api_key proxy_host proxy_port
       proxy_user proxy_pass host port path_prefix http_open_timeout 
       http_read_timeout max_retries).each do |var|
      Postmark.instance_variable_set(:"@#{var}", nil)
    end
  end
end

RSpec::Matchers.define :be_serialized_to do |json|
  match do |mail_message|
    Postmark.convert_message_to_options_hash(mail_message).should == JSON.parse(json)
  end
end
