# frozen_string_literal: true

module TextToSqlAssistant
  module Providers
    class Anthropic < Base
      URL = "https://api.anthropic.com/v1/messages"

      def complete(system_prompt, user_message)
        data = post_json(
          URI(URL),
          {
            "x-api-key" => @api_key,
            "anthropic-version" => "2023-06-01",
            "content-type" => "application/json"
          },
          {
            model: @model,
            max_tokens: 2048,
            system: system_prompt,
            messages: [{ role: "user", content: user_message }]
          }
        )
        data.dig("content", 0, "text")
      end
    end
  end
end
