require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name        = "postmark"
    gem.summary     = %Q{Official Postmark API wrapper.}
    gem.description = %Q{Use this gem to send emails through Postmark HTTP API and retrieve info about bounces.}
    gem.email       = "ilya@wildbit.com"
    gem.homepage    = "http://postmarkapp.com"
    gem.authors     = ["Petyo Ivanov", "Ilya Sabanin", "Artem Chistyakov"]

    gem.add_development_dependency "rspec"
    gem.add_development_dependency "activesupport"
    gem.add_development_dependency "json"
    gem.add_development_dependency "ruby-debug"
    gem.add_development_dependency "fakeweb"
    gem.add_development_dependency "fakeweb-matcher"
    gem.add_development_dependency "timecop"
    gem.add_development_dependency "yajl-ruby"

    gem.post_install_message = %q[
      ==================
      Thanks for installing the postmark gem. If you don't have an account, please sign up at http://postmarkapp.com/.
      Review the README.rdoc for implementation details and examples.
      ==================
    ]
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: sudo gem install jeweler"
end

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.spec_files = FileList['spec/**/*_spec.rb']
end

Spec::Rake::SpecTask.new(:rcov) do |spec|
  spec.libs << 'lib' << 'spec'
  spec.pattern = 'spec/**/*_spec.rb'
  spec.rcov = true
end

task :spec => :check_dependencies

task :default => :spec

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  if File.exist?('VERSION')
    version = File.read('VERSION')
  else
    version = ""
  end

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "postmark #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
