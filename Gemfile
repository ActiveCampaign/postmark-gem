source "http://rubygems.org"

# Specify your gem's dependencies in postmark.gemspec
gemspec

# rake 11.0+ won't install on Ruby < 1.9
gem 'rake', '< 11.0.0', :platforms => [:ruby_18]
# json 2.0+ won't install on Ruby < 2.0
gem 'json', '< 2.0.0', :platforms => [:ruby_18, :ruby_19]

group :test do
  gem 'rspec', '~> 2.14.0'
  gem 'fakeweb'
  gem 'fakeweb-matcher'
  gem 'mime-types', '~> 1.25.1'
  gem 'activesupport', '~> 3.2.0'
  gem 'i18n', '~> 0.6.0'
  gem 'yajl-ruby', '~> 1.0', :platforms => [:mingw, :mswin, :ruby]
end