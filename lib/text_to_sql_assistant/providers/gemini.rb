# frozen_string_literal: true

module TextToSqlAssistant
  module Providers
    class Gemini < Base
      URL = "https://generativelanguage.googleapis.com/v1beta/models/%{model}:generateContent"

      def complete(system_prompt, user_message)
        uri = URI(format(URL, model: @model))
        uri.query = "key=#{@api_key}"

        data = post_json(
          uri,
          { "Content-Type" => "application/json" },
          {
            system_instruction: { parts: [{ text: system_prompt }] },
            contents: [{ role: "user", parts: [{ text: user_message }] }],
            generationConfig: { maxOutputTokens: 2048 }
          }
        )
        data.dig("candidates", 0, "content", "parts", 0, "text")
      end
    end
  end
end
