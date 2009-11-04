# Generated by jeweler
# DO NOT EDIT THIS FILE
# Instead, edit Jeweler::Tasks in Rakefile, and run `rake gemspec`
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{postmark}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Petyo Ivanov"]
  s.date = %q{2009-11-04}
  s.description = %q{Ruby gem for sending emails through http://postmarkapp.com HTTP API. It relieas on TMail::Mail for message construction.}
  s.email = %q{underlog@gmail.com}
  s.extra_rdoc_files = [
    "LICENSE",
     "README.rdoc"
  ]
  s.files = [
    ".document",
     ".gitignore",
     ".rake_tasks",
     "LICENSE",
     "README.rdoc",
     "Rakefile",
     "VERSION",
     "features/postmark.feature",
     "features/step_definitions/postmark_steps.rb",
     "features/support/env.rb",
     "lib/postmark.rb",
     "lib/postmark/tmail_mail_extension.rb",
     "lib/postmark/tmail_mail_extension.rb",
     "postmark.gemspec",
     "spec/postmark_spec.rb",
     "spec/spec.opts",
     "spec/spec_helper.rb"
  ]
  s.homepage = %q{http://postmarkapp.com}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Ruby gem for sending emails through http://postmarkapp.com HTTP API}
  s.test_files = [
    "spec/postmark_spec.rb",
     "spec/spec_helper.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>, [">= 0"])
      s.add_development_dependency(%q<cucumber>, [">= 0"])
      s.add_runtime_dependency(%q<tmail>, [">= 0"])
    else
      s.add_dependency(%q<rspec>, [">= 0"])
      s.add_dependency(%q<cucumber>, [">= 0"])
      s.add_dependency(%q<tmail>, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>, [">= 0"])
    s.add_dependency(%q<cucumber>, [">= 0"])
    s.add_dependency(%q<tmail>, [">= 0"])
  end
end
