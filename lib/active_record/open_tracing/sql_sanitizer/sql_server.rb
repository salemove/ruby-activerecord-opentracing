# frozen_string_literal: true

module ActiveRecord
  module OpenTracing
    module SqlSanitizer
      class SqlServer < Base
        def substitutions
          [
            [SQLSERVER_EXECUTESQL, '\1'],
            [SQLSERVER_REMOVE_INTEGERS, "?"],
            [SQLSERVER_IN_CLAUSE, "IN (?)"]
          ]
        end
      end
    end
  end
end
