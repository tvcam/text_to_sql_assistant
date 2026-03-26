# frozen_string_literal: true

module TextToSqlAssistant
  class Configuration
    attr_accessor :provider,        # :anthropic, :openai, :ollama, or custom class
                  :api_key,
                  :model,
                  :max_rows,
                  :query_timeout,   # seconds
                  :blocked_columns,
                  :blocked_tables,
                  :log_queries,
                  :logger,
                  :on_query         # callback proc for audit logging

    def initialize
      @provider = :anthropic
      @model = nil # auto-detect based on provider
      @max_rows = 50
      @query_timeout = 5
      @blocked_columns = %w[
        encrypted_password reset_password_token confirmation_token
        unconfirmed_email temp_password secret_key api_key api_secret
      ]
      @blocked_tables = %w[information_schema mysql performance_schema sys]
      @log_queries = false
      @logger = nil
      @on_query = nil
    end

    def default_model
      case provider
      when :anthropic then "claude-haiku-4-5-20251001"
      when :openai    then "gpt-4o-mini"
      when :gemini    then "gemini-2.0-flash"
      else
        raise ConfigurationError, "No default model for provider #{provider}. Set config.model explicitly."
      end
    end

    def effective_model
      model || default_model
    end
  end
end
