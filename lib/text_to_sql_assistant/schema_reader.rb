# frozen_string_literal: true

module TextToSqlAssistant
  # Auto-reads database schema from an ActiveRecord connection.
  # No manual schema description needed.
  class SchemaReader
    def initialize(connection)
      @connection = connection
    end

    def read
      tables = @connection.tables.reject { |t| system_table?(t) }

      tables.map do |table|
        columns = @connection.columns(table).map do |col|
          "#{col.name}(#{col.type}#{col.null ? '' : ', NOT NULL'}#{col.default ? ", default: #{col.default}" : ''})"
        end
        "- **#{table}**: #{columns.join(', ')}"
      end.join("\n")
    end

    private

    def system_table?(name)
      %w[ar_internal_metadata schema_migrations].include?(name) ||
        TextToSqlAssistant.configuration.blocked_tables.any? { |bt| name.downcase.include?(bt) }
    end
  end
end
