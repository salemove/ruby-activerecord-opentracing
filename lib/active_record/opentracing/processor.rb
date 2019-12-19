# frozen_string_literal: true

module ActiveRecord
  module OpenTracing
    class Processor
      DEFAULT_OPERATION_NAME = 'sql.query'
      COMPONENT_NAME = 'ActiveRecord'
      SPAN_KIND = 'client'
      DB_TYPE = 'sql'

      def initialize(tracer)
        @tracer = tracer
      end

      def call(_event_name, start, finish, _id, payload)
        span = @tracer.start_span(
          payload[:name] || DEFAULT_OPERATION_NAME,
          start_time: start,
          tags: {
            'component' => COMPONENT_NAME,
            'span.kind' => SPAN_KIND,
            'db.instance' => db_instance,
            'db.cached' => payload.fetch(:cached, false),
            'db.statement' => payload.fetch(:sql).squish,
            'db.type' => DB_TYPE,
            'peer.address' => db_address
          }
        )

        if (exception = payload[:exception_object])
          span.set_tag('error', true)
          span.log_kv(
            event: 'error',
            'error.kind': exception.class.to_s,
            'error.object': exception,
            message: exception.message,
            stack: exception.backtrace.join("\n")
          )
        end

        span.finish(end_time: finish)
      end

      private

      def db_instance
        @db_instance ||= db_config.fetch(:database)
      end

      def db_address
        @db_address ||= begin
          connection_config = ActiveRecord::Base.connection_config
          username = connection_config[:username]
          host = connection_config[:host]
          database = connection_config.fetch(:database)
          vendor = connection_config.fetch(:adapter)

          str = String.new('')
          str << "#{vendor}://"
          str << username if username
          str << "@#{host}" if host
          str << "/#{database}"
          str
        end
      end

      def db_config
        @db_config ||= ActiveRecord::Base.connection_config
      end
    end
  end
end
