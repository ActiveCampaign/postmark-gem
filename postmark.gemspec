# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "postmark/version"

Gem::Specification.new do |s|
  s.name        = "postmark"
  s.version     = Postmark::VERSION
  s.authors     = ["Artem Chistyakov"]
  s.email       = ["tema@wildbit.com"]
  s.homepage    = ""
  s.summary     = %q{TODO: Write a gem summary}
  s.description = %q{TODO: Write a gem description}

  s.rubyforge_project = "postmark"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"

  s.add_development_dependency(%q<tmail>, [">= 0"])
  s.add_development_dependency(%q<mail>, [">= 0"])
  s.add_development_dependency(%q<rspec>, [">= 0"])
  s.add_development_dependency(%q<activesupport>, [">= 0"])
  s.add_development_dependency(%q<json>, [">= 0"])
  s.add_development_dependency(%q<fakeweb>, [">= 0"])
  s.add_development_dependency(%q<fakeweb-matcher>, [">= 0"])
  s.add_development_dependency(%q<timecop>, [">= 0"])
  s.add_development_dependency(%q<yajl-ruby>, [">= 0"])

  if RUBY_VERSION < '1.9.0'
    s.add_development_dependency(%q<ruby-debug>, [">= 0"])
  else
    s.add_development_dependency(%q<ruby-debug19>, [">= 0"])
  end

end

