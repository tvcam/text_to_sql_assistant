# frozen_string_literal: true

module TextToSqlAssistant
  class QueryValidator
    DANGEROUS_KEYWORDS = %w[INSERT UPDATE DELETE DROP ALTER TRUNCATE CREATE GRANT REVOKE].freeze
    BLOCKED_PATTERNS = ["INTO OUTFILE", "INTO DUMPFILE", "LOAD_FILE", "BENCHMARK("].freeze

    def initialize(config)
      @config = config
    end

    def validate!(sql)
      normalized = sql.strip.gsub(/\s+/, " ").upcase

      validate_select_only!(normalized)
      validate_no_dangerous_keywords!(normalized)
      validate_no_sensitive_columns!(normalized)
      validate_no_blocked_patterns!(normalized)

      ensure_limit(sql, normalized)
    end

    private

    def validate_select_only!(normalized)
      unless normalized.start_with?("SELECT")
        raise QueryBlockedError, "Only SELECT queries are allowed"
      end
    end

    def validate_no_dangerous_keywords!(normalized)
      words = normalized.split(/[\s;,()]+/)
      found = DANGEROUS_KEYWORDS.select { |kw| words.include?(kw) }
      if found.any?
        raise QueryBlockedError, "Query contains forbidden keyword: #{found.join(', ')}"
      end
    end

    def validate_no_sensitive_columns!(normalized)
      blocked = @config.blocked_columns.map(&:upcase)
      found = blocked.select { |col| normalized.include?(col) }
      if found.any?
        raise QueryBlockedError, "Query references sensitive column: #{found.join(', ')}"
      end
    end

    def validate_no_blocked_patterns!(normalized)
      found = BLOCKED_PATTERNS.select { |pat| normalized.include?(pat) }
      if found.any?
        raise QueryBlockedError, "Query contains blocked pattern: #{found.join(', ')}"
      end
    end

    def ensure_limit(sql, normalized)
      if normalized.include?("LIMIT")
        sql.chomp(";")
      else
        "#{sql.chomp(';')} LIMIT #{@config.max_rows}"
      end
    end
  end
end
