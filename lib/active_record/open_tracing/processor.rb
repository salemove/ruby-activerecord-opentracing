# frozen_string_literal: true

module ActiveRecord
  module OpenTracing
    class Processor
      DEFAULT_OPERATION_NAME = "sql.query"
      COMPONENT_NAME = "ActiveRecord"
      SPAN_KIND = "client"
      DB_TYPE = "sql"

      attr_reader :tracer, :sanitizer, :sql_logging_enabled

      def initialize(tracer, sanitizer: nil, sql_logging_enabled: true)
        @tracer = tracer
        @sanitizer = sanitizer
        @sql_logging_enabled = sql_logging_enabled
      end

      def call(_event_name, start, finish, _id, payload)
        span = tracer.start_span(
          payload[:name] || DEFAULT_OPERATION_NAME,
          start_time: start,
          tags: tags_for_payload(payload)
        )

        if (exception = payload[:exception_object])
          span.set_tag("error", true)
          span.log_kv(exception_metadata(exception))
        end

        span.finish(end_time: finish)
      end

      private

      def exception_metadata(exception)
        {
          event: "error",
          'error.kind': exception.class.to_s,
          'error.object': exception,
          message: exception.message,
          stack: exception.backtrace.join("\n")
        }
      end

      def tags_for_payload(payload)
        {
          "component" => COMPONENT_NAME,
          "span.kind" => SPAN_KIND,
          "db.instance" => db_instance,
          "db.cached" => payload.fetch(:cached, false),
          "db.type" => DB_TYPE,
          "peer.address" => peer_address_tag
        }.merge(db_statement(payload))
      end

      def db_statement(payload)
        sql_logging_enabled ? { "db.statement" => sanitize_sql(payload.fetch(:sql).squish) } : {}
      end

      def sanitize_sql(sql)
        sanitizer ? sanitizer.sanitize(sql) : sql
      end

      def peer_address_tag
        @peer_address_tag ||= [
          "#{connection_config.fetch(:adapter)}://",
          connection_config[:username],
          connection_config[:host] && "@#{connection_config[:host]}",
          "/#{db_instance}"
        ].join
      end

      def db_instance
        @db_instance ||= connection_config.fetch(:database)
      end

      def connection_config
        @connection_config ||= ActiveRecord::Base.connection_config
      end
    end
  end
end
