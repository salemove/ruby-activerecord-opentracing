# frozen_string_literal: true

require "active_record/open_tracing/sql_sanitizer/base"
require "active_record/open_tracing/sql_sanitizer/mysql"
require "active_record/open_tracing/sql_sanitizer/postgres"
require "active_record/open_tracing/sql_sanitizer/sql_server"
require "active_record/open_tracing/sql_sanitizer/sqlite"
require "active_record/open_tracing/sql_sanitizer/regexes"

module ActiveRecord
  module OpenTracing
    module SqlSanitizer
      KLASSES = {
        mysql: Mysql,
        postgres: Postgres,
        sql_server: SqlServer,
        sqlite: Sqlite
      }.freeze

      class << self
        def build_sanitizer(sanitizer_name)
          sanitizer_klass(sanitizer_name).new
        end

        private

        def sanitizer_klass(sanitizer_name)
          key = KLASSES.keys.detect do |name|
            sanitizer_name.to_sym == name
          end || (raise NameError, "Unknown sanitizer #{sanitizer_name.inspect}")

          KLASSES.fetch(key)
        end
      end
    end
  end
end
