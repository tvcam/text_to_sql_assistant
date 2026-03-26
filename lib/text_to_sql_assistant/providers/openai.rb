# frozen_string_literal: true

module TextToSqlAssistant
  module Providers
    class OpenAI < Base
      URL = "https://api.openai.com/v1/chat/completions"

      def complete(system_prompt, user_message)
        data = post_json(
          URI(URL),
          {
            "Authorization" => "Bearer #{@api_key}",
            "Content-Type" => "application/json"
          },
          {
            model: @model,
            max_tokens: 2048,
            messages: [
              { role: "system", content: system_prompt },
              { role: "user", content: user_message }
            ]
          }
        )
        data.dig("choices", 0, "message", "content")
      end
    end
  end
end
