# frozen_string_literal: true

module ActiveRecord
  module OpenTracing
    class Processor
      DEFAULT_OPERATION_NAME = "sql.query"
      COMPONENT_NAME = "ActiveRecord"
      SPAN_KIND = "client"
      DB_TYPE = "sql"

      # Used to guess what type of query is running based on the first word of the query
      #
      # Categories are
      # table: Run an action against a table changes the table metadata or configuration
      # read: Read from the database
      # write: Write or delete records to the database
      # unknown: Can't tell the query action from the first word of the query
      # not_found: First word of the query is not in this list
      QUERY_CATEGORIES = {
        alter: "table",
        call: "unknown", # run a subquery
        create: "table",
        delete: "write",
        drop: "table",
        do: "read",
        handler: "table", # table metadata
        import: "write",
        insert: "write",
        load: "write", # covers LOAD XML and LOAD DATA queries
        rename: "table",
        replace: "write", # insert, on duplicate overwrite
        select: "read",
        table: "read", # similar to select
        truncate: "table",
        update: "write",
        values: "unknown", # generates rows to use as a table but doesn't hit the database
        with: "unknown" # sets up subqueries in preparation for other queries
      }

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

      # rubocop:disable Metrics/MethodLength
      def db_statement(payload)
        if sql_logging_enabled
          query_sql = sanitize_sql(payload.fetch(:sql).squish)
          first_word = query_sql.split.first&.downcase || ""

          {
            "db.statement" => query_sql,
            "db.query_type" => first_word,
            "db.query_category" => QUERY_CATEGORIES[first_word.to_sym] || "not_found"
          }
        else
          {}
        end
      end
      # rubocop:enable Metrics/MethodLength

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
        # Rails 6.2 will deprecate ActiveRecord::Base.connection_config
        @connection_config ||=
          ActiveRecord::Base.try(:connection_db_config)&.configuration_hash || ActiveRecord::Base.connection_config
      end
    end
  end
end
