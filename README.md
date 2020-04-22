# ActiveRecord::OpenTracing

Adds OpenTracing instrumentation to ActiveRecord

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'activerecord-opentracing'
```

## Usage

```ruby
require 'opentracing'
OpenTracing.global_tracer = TracerImplementation.new

require 'active_record/opentracing'
ActiveRecord::OpenTracing.instrument
```

# Development

## Gem documentation

You can find the documentation by going to CircleCI, looking for the `build` job, going to Artifacts and clicking on `index.html`. A visual guide on this can be found in our wiki at [Gems Development: Where to find documentation for our gems](https://wiki.doximity.com/articles/gems-development-where-to-find-documentation-for-our-gems).

## Gem development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake spec` to run the tests.
You can also run `bundle console` for an interactive prompt that will allow you to experiment.

This repository uses a gem publishing mechanism on the CI configuration, meaning most work related with cutting a new
version is done automatically.

To release a new version, follow the [wiki instructions](https://wiki.doximity.com/articles/gems-development-releasing-new-versions).