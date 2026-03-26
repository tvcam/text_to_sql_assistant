# frozen_string_literal: true

require "spec_helper"

RSpec.describe TextToSqlAssistant::SchemaReader do
  let(:reader) { described_class.new(ActiveRecord::Base.connection) }

  describe "#read" do
    it "returns schema description" do
      schema = reader.read
      expect(schema).to include("users")
      expect(schema).to include("orders")
    end

    it "includes column names and types" do
      schema = reader.read
      expect(schema).to include("email")
      expect(schema).to include("first_name")
      expect(schema).to include("total_cents")
    end

    it "excludes system tables" do
      schema = reader.read
      expect(schema).not_to include("schema_migrations")
      expect(schema).not_to include("ar_internal_metadata")
    end
  end
end
