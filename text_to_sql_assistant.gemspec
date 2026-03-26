# frozen_string_literal: true

Gem::Specification.new do |spec|
  spec.name          = "text_to_sql_assistant"
  spec.version       = "0.1.0"
  spec.authors       = ["Vibol Teav"]
  spec.email         = ["vt@gotabs.net"]
  spec.summary       = "Natural language to SQL query assistant for Ruby/Rails apps"
  spec.description   = "Ask questions in plain English, get SQL queries and human-readable answers. " \
                        "Works with any LLM provider (Anthropic Claude, OpenAI, Ollama, or custom). " \
                        "Includes security guardrails: SELECT-only, column blocklists, query timeouts, audit logging."
  spec.homepage      = "https://github.com/tvcam/text_to_sql_assistant"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 3.1.0"

  spec.files         = Dir["lib/**/*", "LICENSE", "README.md"]
  spec.require_paths = ["lib"]

  spec.add_dependency "activerecord", ">= 7.0"

  spec.metadata = {
    "homepage_uri" => spec.homepage,
    "source_code_uri" => spec.homepage,
    "changelog_uri" => "#{spec.homepage}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{spec.homepage}/issues"
  }
end
