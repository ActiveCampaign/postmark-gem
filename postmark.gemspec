# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{postmark}
  s.version = "0.9.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Petyo Ivanov", "Ilya Sabanin"]
  s.date = %q{2010-10-13}
  s.description = %q{Ruby gem for sending emails through http://postmarkapp.com HTTP API.}
  s.email = %q{underlog@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".bundle/config",
     ".document",
     ".gitignore",
     ".rake_tasks",
     "CHANGELOG.rdoc",
     "Gemfile",
     "Gemfile.lock",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "features/postmark.feature",
     "features/step_definitions/postmark_steps.rb",
     "features/support/env.rb",
     "init.rb",
     "lib/postmark.rb",
     "lib/postmark/attachments_fix_for_mail.rb",
     "lib/postmark/bounce.rb",
     "lib/postmark/handlers/mail.rb",
     "lib/postmark/http_client.rb",
     "lib/postmark/json.rb",
     "lib/postmark/message_extensions/mail.rb",
     "lib/postmark/message_extensions/shared.rb",
     "lib/postmark/response_parsers/active_support.rb",
     "lib/postmark/response_parsers/json.rb",
     "lib/postmark/response_parsers/yajl.rb",
     "postmark.gemspec",
     "spec/bounce_spec.rb",
     "spec/postmark_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://postmarkapp.com}
  s.post_install_message = %q{
      ==================
      Thanks for installing the postmark gem. If you don't have an account, please sign up at http://postmarkapp.com/.
      Review the README.rdoc for implementation details and examples.
      ==================
    }
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{Ruby gem for sending emails through http://postmarkapp.com HTTP API}
  s.test_files = [
    "spec/bounce_spec.rb",
     "spec/postmark_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<cucumber>, [">= 0"])
      s.add_runtime_dependency(%q<mail>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<cucumber>, [">= 0"])
      s.add_dependency(%q<mail>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<cucumber>, [">= 0"])
    s.add_dependency(%q<mail>, [">= 0"])
  end
end

