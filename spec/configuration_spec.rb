# frozen_string_literal: true

require "spec_helper"

RSpec.describe TextToSqlAssistant::Configuration do
  let(:config) { described_class.new }

  it "defaults to anthropic provider" do
    expect(config.provider).to eq(:anthropic)
  end

  it "defaults to 50 max rows" do
    expect(config.max_rows).to eq(50)
  end

  it "defaults to 5 second timeout" do
    expect(config.query_timeout).to eq(5)
  end

  it "has default blocked columns" do
    expect(config.blocked_columns).to include("encrypted_password")
    expect(config.blocked_columns).to include("reset_password_token")
  end

  describe "#default_model" do
    it "returns haiku for anthropic" do
      config.provider = :anthropic
      expect(config.default_model).to eq("claude-haiku-4-5-20251001")
    end

    it "returns gpt-4o-mini for openai" do
      config.provider = :openai
      expect(config.default_model).to eq("gpt-4o-mini")
    end

    it "returns gemini-2.0-flash for gemini" do
      config.provider = :gemini
      expect(config.default_model).to eq("gemini-2.0-flash")
    end
  end

  describe "#effective_model" do
    it "uses explicit model when set" do
      config.model = "my-custom-model"
      expect(config.effective_model).to eq("my-custom-model")
    end

    it "falls back to default when model is nil" do
      config.provider = :openai
      expect(config.effective_model).to eq("gpt-4o-mini")
    end
  end
end
