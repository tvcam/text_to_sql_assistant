# frozen_string_literal: true

module TextToSqlAssistant
  class Assistant
    SYSTEM_PROMPT = <<~PROMPT
      You are a SQL expert. Given a database schema and a question, generate a SELECT query to answer it.

      Rules:
      1. ONLY generate SELECT queries. Never INSERT, UPDATE, DELETE, DROP, or ALTER.
      2. Always LIMIT results to %{max_rows} rows.
      3. Use JOINs to show human-readable names instead of IDs where possible.
      4. Format dates readably.
      5. Explain your query logic briefly, then provide the SQL in a ```sql block.

      ## Schema
      %{schema}
    PROMPT

    def initialize(connection: nil, schema: nil, provider: nil, api_key: nil, model: nil)
      @connection = connection || ActiveRecord::Base.connection
      @config = TextToSqlAssistant.configuration
      @provider = build_provider(provider, api_key, model)
      @schema = schema || SchemaReader.new(@connection).read
      @validator = QueryValidator.new(@config)
    end

    def ask(question)
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      # Step 1: Generate SQL
      prompt = format(SYSTEM_PROMPT, max_rows: @config.max_rows, schema: @schema)
      sql_response = @provider.complete(prompt, question)

      # Step 2: Extract SQL
      sql = extract_sql(sql_response)
      unless sql
        return { answer: "Could not generate a valid SQL query.", sql: nil, results: [], total_rows: 0,
                 duration_ms: duration_since(start_time) }
      end

      # Step 3: Validate and execute
      begin
        validated_sql = @validator.validate!(sql)
        set_timeout
        data = @connection.select_all(validated_sql).to_a
      rescue QueryBlockedError => e
        return { answer: "Query blocked: #{e.message}", sql: sql, results: [], total_rows: 0,
                 duration_ms: duration_since(start_time) }
      rescue ActiveRecord::StatementInvalid => e
        return { answer: "SQL error: #{e.message.split("\n").first}", sql: sql, results: [], total_rows: 0,
                 duration_ms: duration_since(start_time) }
      end

      # Step 4: Interpret results
      preview = data.first(20).map(&:to_h).to_json
      answer = @provider.complete(
        prompt,
        "I asked: #{question}\n\nSQL:\n```sql\n#{validated_sql}\n```\n\nResults (#{data.length} rows):\n#{preview}\n\nProvide a clear answer."
      )

      duration = duration_since(start_time)

      result = {
        answer: answer,
        sql: validated_sql,
        results: data.first(10),
        total_rows: data.length,
        duration_ms: duration
      }

      log_query(question, result) if @config.log_queries
      @config.on_query&.call(question, result)

      result
    end

    private

    def build_provider(provider_arg, api_key_arg, model_arg)
      # Accept a pre-built provider instance directly
      return provider_arg if provider_arg.is_a?(Providers::Base)

      provider_name = provider_arg || @config.provider
      api_key = api_key_arg || @config.api_key
      model = model_arg || @config.effective_model

      case provider_name
      when :anthropic
        Providers::Anthropic.new(api_key: api_key, model: model)
      when :openai
        Providers::OpenAI.new(api_key: api_key, model: model)
      when :gemini
        Providers::Gemini.new(api_key: api_key, model: model)
      else
        if provider_name.respond_to?(:new)
          provider_name.new(api_key: api_key, model: model)
        else
          raise ConfigurationError, "Unknown provider: #{provider_name}. Use :anthropic, :openai, :gemini, or a custom class."
        end
      end
    end

    def extract_sql(response)
      return nil unless response

      match = response.match(/```sql\s*\n?(.*?)\n?```/m)
      return match[1].strip if match

      match = response.match(/(SELECT\s+.+?;)/im)
      match ? match[1].strip : nil
    end

    def set_timeout
      timeout_ms = @config.query_timeout * 1000
      @connection.execute("SET SESSION MAX_EXECUTION_TIME = #{timeout_ms}") rescue nil
    end

    def duration_since(start_time)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round(2)
    end

    def log_query(question, result)
      logger = @config.logger || (defined?(Rails) ? Rails.logger : nil)
      logger&.info("[TextToSqlAssistant] Q: #{question} | SQL: #{result[:sql]&.truncate(100)} | Rows: #{result[:total_rows]} | #{result[:duration_ms]}ms")
    end
  end
end
