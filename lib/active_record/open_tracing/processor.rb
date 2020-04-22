# frozen_string_literal: true

module ActiveRecord
  module OpenTracing
    class Processor
      DEFAULT_OPERATION_NAME = "sql.query"
      COMPONENT_NAME = "ActiveRecord"
      SPAN_KIND = "client"
      DB_TYPE = "sql"

      def initialize(tracer)
        @tracer = tracer
      end

      def call(_event_name, start, finish, _id, payload)
        span = @tracer.start_span(
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
          "db.statement" => payload.fetch(:sql).squish,
          "db.type" => DB_TYPE,
          "peer.address" => db_address
        }
      end

      def db_instance
        @db_instance ||= db_config.fetch(:database)
      end

      def db_address
        @db_address ||= [
          adapter_str,
          username_str,
          host_str,
          database_str
        ].join
      end

      def adapter_str
        "#{connection_config.fetch(:adapter)}://"
      end

      def username_str
        connection_config[:username]
      end

      def host_str
        "@#{connection_config[:host]}" if connection_config[:host]
      end

      def database_str
        "/#{connection_config.fetch(:database)}"
      end

      def connection_config
        ActiveRecord::Base.connection_config
      end

      def db_config
        @db_config ||= ActiveRecord::Base.connection_config
      end
    end
  end
end
