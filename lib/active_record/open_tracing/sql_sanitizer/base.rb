# frozen_string_literal: true

module ActiveRecord
  module OpenTracing
    module SqlSanitizer
      class Base
        require "active_record/open_tracing/sql_sanitizer/regexes"
        include ActiveRecord::OpenTracing::SqlSanitizer::Regexes

        def sanitize(sql)
          scrubbed = scrub(sql.dup)
          apply_substitutions(scrubbed)
        end

        private

        def substitutions
          raise NotImplementedError
        end

        def apply_substitutions(str)
          substitutions.inject(str.dup) do |memo, (regex, replacement)|
            if replacement.respond_to?(:call)
              memo.gsub(regex, &replacement)
            else
              memo.gsub(regex, replacement)
            end
          end.strip
        end

        def encodings?(encodings = %w[UTF-8 binary])
          encodings.all? do |enc|
            begin
              Encoding.find(enc)
            rescue StandardError
              false
            end
          end
        end

        MAX_SQL_LENGTH = 16384

        def scrub(str)
          # safeguard - don't sanitize or scrub large SQL statements
          return "" if !str.is_a?(String) || str.length > MAX_SQL_LENGTH

          # Whatever encoding it is, it is valid and we can operate on it
          return str if str.valid_encoding?

          # Prefer scrub over convert
          if str.respond_to?(:scrub)
            str.scrub("_")
          elsif encodings?(%w[UTF-8 binary])
            str.encode("UTF-8", "binary", invalid: :replace, undef: :replace, replace: "_")
          else
            # Unable to scrub invalid sql encoding, returning empty string
            ""
          end
        end
      end
    end
  end
end
