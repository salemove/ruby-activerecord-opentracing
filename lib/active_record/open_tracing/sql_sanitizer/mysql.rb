# frozen_string_literal: true

module ActiveRecord
  module OpenTracing
    module SqlSanitizer
      class Mysql < Base
        def substitutions
          [
            [MYSQL_VAR_INTERPOLATION, ""],
            [MYSQL_REMOVE_SINGLE_QUOTE_STRINGS, "?"],
            [MYSQL_REMOVE_DOUBLE_QUOTE_STRINGS, "?"],
            [MYSQL_REMOVE_INTEGERS, "?"],
            [MYSQL_IN_CLAUSE, "IN (?)"],
            [MULTIPLE_QUESTIONS, "?"]
          ]
        end
      end
    end
  end
end
