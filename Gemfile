source "http://rubygems.org"

# Specify your gem's dependencies in postmark.gemspec
gemspec

group :test do
  gem 'rspec', '~> 3.7', "< 3.10" # until https://github.com/rspec/rspec-support/pull/537 gets merged
  gem 'rspec-its', '~> 1.2'
  gem 'fakeweb', :git => 'https://github.com/chrisk/fakeweb.git'
  gem 'fakeweb-matcher'
  gem 'mime-types'
  gem 'activesupport'
  gem 'i18n', '~> 0.6.0'

  # To support Ruby version <= 2.6
  gem 'minitest', '<= 5.15.0'
  gem 'yajl-ruby', '<= 1.4.1', :platforms => [:mingw, :mswin, :ruby]
end
