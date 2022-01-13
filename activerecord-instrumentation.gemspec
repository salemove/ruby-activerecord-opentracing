# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "active_record/open_tracing/version"

Gem::Specification.new do |spec|
  spec.name          = "activerecord-instrumentation"
  spec.version       = ActiveRecord::OpenTracing::VERSION
  spec.authors       = ["SaleMove TechMovers", "Doximity"]
  spec.email         = ["ops@doximity.com"]

  spec.summary       = "ActiveRecord OpenTracing intrumenter"
  spec.description   = ""
  spec.homepage      = "https://github.com/doximity/ruby-activerecord-opentracing"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(bin|test|spec|features|vendor|tasks|tmp)/}) }
  end
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.17"
  spec.add_development_dependency "dox-style"
  spec.add_development_dependency "opentracing_test_tracer", "~> 0.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~> 3.9.0"
  spec.add_development_dependency "rspec_junit_formatter"
  spec.add_development_dependency "rubocop", "~> 0.78.0"
  spec.add_development_dependency "rubocop-rspec", "~> 1.37.0"
  spec.add_development_dependency "sdoc"
  spec.add_development_dependency "sqlite3", "~> 1.4.2"

  spec.add_dependency "activerecord"
  spec.add_dependency "opentracing", "~> 0.5"
end
