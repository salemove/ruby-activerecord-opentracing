lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_record/opentracing/version'

Gem::Specification.new do |spec|
  spec.name          = 'activerecord-opentracing'
  spec.version       = ActiveRecord::OpenTracing::VERSION
  spec.authors       = ['SaleMove TechMovers']
  spec.email         = ['techmovers@salemove.com']

  spec.summary       = 'ActiveRecord OpenTracing intrumenter'
  spec.description   = ''
  spec.homepage      = 'https://github.com/salemove/ruby-activerecord-opentracing'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'opentracing_test_tracer', '~> 0.1'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'rubocop', '~> 0.54.0'
  spec.add_development_dependency 'rubocop-rspec', '~> 1.24.0'
  spec.add_development_dependency 'sqlite3', '~> 1.3.13'

  spec.add_dependency 'activerecord', '~> 5.0'
  spec.add_dependency 'opentracing', '~> 0.3'
end
