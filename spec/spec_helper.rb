$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'rubygems'
require 'mail'
require 'tmail'
require 'postmark'
require 'active_support'
require 'json'
require 'ruby-debug'
require 'fakeweb'
require 'fakeweb_matcher'
require 'timecop'
require 'spec'
require 'spec/autorun'

if ENV['JSONGEM']
  # `JSONGEM=Yajl rake spec`
  Postmark.response_parser_class = ENV['JSONGEM'].to_sym
  puts "Setting ResponseParser class to #{Postmark::ResponseParsers.const_get Postmark.response_parser_class}"
end

Spec::Runner.configure do |config|

end
