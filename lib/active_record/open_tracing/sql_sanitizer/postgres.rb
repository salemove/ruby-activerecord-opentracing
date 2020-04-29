# frozen_string_literal: true

module ActiveRecord
  module OpenTracing
    module SqlSanitizer
      class Postgres < Base
        def substitutions
          [
            [PSQL_PLACEHOLDER, "?"],
            [PSQL_VAR_INTERPOLATION, ""],
            [PSQL_AFTER_WHERE, ->(c) { c.gsub(PSQL_REMOVE_STRINGS, "?") }],
            [PSQL_REMOVE_INTEGERS, "?"],
            [PSQL_IN_CLAUSE, "IN (?)"],
            [MULTIPLE_SPACES, " "]
          ]
        end
      end
    end
  end
end
