# frozen_string_literal: true

require "net/http"
require "json"
require "uri"

module TextToSqlAssistant
  module Providers
    class Base
      def initialize(api_key:, model:)
        @api_key = api_key
        @model = model
      end

      def complete(system_prompt, user_message)
        raise NotImplementedError
      end

      private

      def post_json(uri, headers, body)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        http.read_timeout = 30

        request = Net::HTTP::Post.new(uri)
        headers.each { |k, v| request[k] = v }
        request.body = body.to_json

        response = http.request(request)

        unless response.code.to_i.between?(200, 299)
          raise ProviderError, "#{self.class.name} API error #{response.code}: #{response.body[0..200]}"
        end

        JSON.parse(response.body)
      end
    end
  end
end
