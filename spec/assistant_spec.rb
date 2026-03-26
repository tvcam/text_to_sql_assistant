# frozen_string_literal: true

require "spec_helper"

RSpec.describe TextToSqlAssistant::Assistant do
  let(:stub_provider) { StubProvider.new }

  let(:assistant) do
    described_class.new(
      connection: ActiveRecord::Base.connection,
      provider: stub_provider
    )
  end

  describe "#ask" do
    context "when LLM generates valid SQL" do
      before do
        stub_provider.responses = [
          # Call 1: generate SQL
          "Here's the query:\n```sql\nSELECT first_name, last_name, email FROM users WHERE archived = 0;\n```",
          # Call 2: interpret results
          "There are 2 active users: Alice Smith and Bob Jones."
        ]
      end

      it "returns answer, sql, and results" do
        result = assistant.ask("Who are the active users?")
        expect(result[:answer]).to include("Alice")
        expect(result[:sql]).to include("SELECT")
        expect(result[:total_rows]).to eq(2)
        expect(result[:results].length).to eq(2)
      end

      it "includes duration" do
        result = assistant.ask("Who are the active users?")
        expect(result[:duration_ms]).to be > 0
      end
    end

    context "when LLM generates SQL without code block" do
      before do
        stub_provider.responses = [
          "Try this: SELECT COUNT(*) as cnt FROM users;",
          "There are 3 users total."
        ]
      end

      it "extracts SQL from bare SELECT statement" do
        result = assistant.ask("How many users?")
        expect(result[:sql]).to include("SELECT COUNT")
        expect(result[:total_rows]).to eq(1)
      end
    end

    context "when LLM generates dangerous SQL" do
      before do
        stub_provider.responses = [
          "```sql\nDELETE FROM users;\n```"
        ]
      end

      it "blocks the query" do
        result = assistant.ask("Delete all users")
        expect(result[:answer]).to include("blocked")
        expect(result[:total_rows]).to eq(0)
      end
    end

    context "when LLM generates SQL with sensitive columns" do
      before do
        stub_provider.responses = [
          "```sql\nSELECT email, encrypted_password FROM users;\n```"
        ]
      end

      it "blocks access to sensitive columns" do
        result = assistant.ask("Show passwords")
        expect(result[:answer]).to include("blocked")
      end
    end

    context "when LLM returns no SQL" do
      before do
        stub_provider.responses = [
          "I don't understand the question."
        ]
      end

      it "returns graceful error" do
        result = assistant.ask("asdf gibberish")
        expect(result[:answer]).to include("Could not generate")
        expect(result[:sql]).to be_nil
      end
    end

    context "when SQL has execution error" do
      before do
        stub_provider.responses = [
          "```sql\nSELECT * FROM nonexistent_table;\n```"
        ]
      end

      it "returns the error message" do
        result = assistant.ask("Show me the fake table")
        expect(result[:answer]).to include("SQL error")
      end
    end

    context "with audit callback" do
      it "calls on_query callback" do
        logged = nil
        TextToSqlAssistant.configure do |c|
          c.on_query = ->(q, r) { logged = { question: q, rows: r[:total_rows] } }
        end

        stub_provider.responses = [
          "```sql\nSELECT COUNT(*) FROM users;\n```",
          "3 users"
        ]

        assistant.ask("How many users?")
        expect(logged[:question]).to eq("How many users?")
        expect(logged[:rows]).to eq(1)
      end
    end
  end
end
