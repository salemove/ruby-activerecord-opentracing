# frozen_string_literal: true

require "active_record"
require "opentracing"

require "active_record/open_tracing/version"
require "active_record/open_tracing/processor"
require "active_record/open_tracing/sql_sanitizer"

module ActiveRecord
  module OpenTracing
    # Instruments activerecord for use with OpenTracing
    #
    # @param tracer [OpenTracing::Tracer] The tracer to which to send traces
    # @param sanitizer [Symbol, String, nil] The sanitizer to use. Options are :mysql,
    #   :postgres, :sql_server, :sqlite. If no sanitizer is specified, or a falsy value
    #   is passed, sql will not be sanitized.
    # @param sql_logging [Boolean] Whether to log sql statements to the tracer
    def self.instrument(tracer: ::OpenTracing.global_tracer, sanitizer: nil, sql_logging_enabled: true)
      sql_sanitizer = sanitizer && SqlSanitizer.build_sanitizer(sanitizer)
      processor = Processor.new(tracer, sanitizer: sql_sanitizer, sql_logging_enabled: sql_logging_enabled)

      ActiveSupport::Notifications.subscribe("sql.active_record") do |*args|
        processor.call(*args)
      end
    end
  end
end
