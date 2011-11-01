$:.push File.expand_path("../lib", __FILE__)
require "postmark/version"

Gem::Specification.new do |s|
  s.name = %q{postmark}
  s.version = Postmark::VERSION
  s.authors = [%q{Petyo Ivanov}, %q{Ilya Sabanin}]
  s.homepage = %q{http://postmarkapp.com}
  s.date = %q{2011-08-23}
  s.summary = %q{Official Postmark API wrapper.}
  s.description = %q{Use this gem to send emails through Postmark HTTP API and retrieve info about bounces.}
  s.email = %q{ilya@wildbit.com}
  s.platform    = Gem::Platform::RUBY

  s.add_development_dependency('rake')
  s.add_development_dependency('rspec')
  s.add_development_dependency('activesupport')
  s.add_development_dependency('fakeweb')
  s.add_development_dependency('fakeweb-matcher')
  s.add_development_dependency('timecop')

  s.add_dependency('json')
  s.add_dependency('yajl-ruby')
  s.add_dependency('mail')

  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]

  s.post_install_message = %q{
      ==================
      Thanks for installing the postmark gem. If you don't have an account, please sign up at http://postmarkapp.com/.
      Review the README.rdoc for implementation details and examples.
      ==================
    }

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec/*`.split("\n")
  s.require_paths = ["lib"]
end

