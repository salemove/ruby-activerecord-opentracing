# frozen_string_literal: true

require "active_record"
require "opentracing"

require "active_record/open_tracing/version"
require "active_record/open_tracing/processor"

module ActiveRecord
  module OpenTracing
    def self.instrument(tracer: ::OpenTracing.global_tracer)
      processor = Processor.new(tracer)

      ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        processor.call(*args)
      end

      self
    end
  end
end
