# frozen_string_literal: true

require "active_record"

require_relative "text_to_sql_assistant/version"
require_relative "text_to_sql_assistant/configuration"
require_relative "text_to_sql_assistant/schema_reader"
require_relative "text_to_sql_assistant/query_validator"
require_relative "text_to_sql_assistant/assistant"
require_relative "text_to_sql_assistant/providers/base"
require_relative "text_to_sql_assistant/providers/anthropic"
require_relative "text_to_sql_assistant/providers/openai"
require_relative "text_to_sql_assistant/providers/gemini"

module TextToSqlAssistant
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class QueryBlockedError < Error; end
  class ProviderError < Error; end

  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end

    def new(**kwargs)
      Assistant.new(**kwargs)
    end
  end
end
