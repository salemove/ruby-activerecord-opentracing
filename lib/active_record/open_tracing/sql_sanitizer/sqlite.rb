# frozen_string_literal: true

module ActiveRecord
  module OpenTracing
    module SqlSanitizer
      class Sqlite < Base
        def substitutions
          [
            [SQLITE_VAR_INTERPOLATION, ""],
            [SQLITE_REMOVE_STRINGS, "?"],
            [SQLITE_REMOVE_INTEGERS, "?"],
            [MULTIPLE_SPACES, " "]
          ]
        end
      end
    end
  end
end
