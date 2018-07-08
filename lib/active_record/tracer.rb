# frozen_string_literal: true

require 'active_record'
require 'opentracing'

require 'active_record/tracer/version'
require 'active_record/tracer/processor'

module ActiveRecord
  module Tracer
    def self.instrument(tracer: OpenTracing.global_tracer)
      processor = Processor.new(tracer)

      ActiveSupport::Notifications.subscribe('sql.active_record') do |*args|
        processor.call(*args)
      end

      self
    end
  end
end
