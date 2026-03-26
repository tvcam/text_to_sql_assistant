# frozen_string_literal: true

require "text_to_sql_assistant"
require "active_record"

# In-memory SQLite for testing
ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  create_table :users do |t|
    t.string :email, null: false
    t.string :first_name
    t.string :last_name
    t.string :encrypted_password
    t.string :reset_password_token
    t.boolean :archived, default: false
    t.timestamps
  end

  create_table :orders do |t|
    t.references :user
    t.integer :total_cents
    t.string :status, default: "pending"
    t.timestamps
  end
end

# Seed test data
ActiveRecord::Base.connection.execute("INSERT INTO users (email, first_name, last_name, encrypted_password, archived, created_at, updated_at) VALUES ('alice@test.com', 'Alice', 'Smith', 'xxx', 0, '2026-01-15', '2026-01-15')")
ActiveRecord::Base.connection.execute("INSERT INTO users (email, first_name, last_name, encrypted_password, archived, created_at, updated_at) VALUES ('bob@test.com', 'Bob', 'Jones', 'xxx', 0, '2026-02-20', '2026-02-20')")
ActiveRecord::Base.connection.execute("INSERT INTO users (email, first_name, last_name, encrypted_password, archived, created_at, updated_at) VALUES ('charlie@test.com', 'Charlie', 'Brown', 'xxx', 1, '2026-03-01', '2026-03-01')")
ActiveRecord::Base.connection.execute("INSERT INTO orders (user_id, total_cents, status, created_at, updated_at) VALUES (1, 5000, 'paid', '2026-03-01', '2026-03-01')")
ActiveRecord::Base.connection.execute("INSERT INTO orders (user_id, total_cents, status, created_at, updated_at) VALUES (1, 3000, 'paid', '2026-03-10', '2026-03-10')")
ActiveRecord::Base.connection.execute("INSERT INTO orders (user_id, total_cents, status, created_at, updated_at) VALUES (2, 7500, 'pending', '2026-03-15', '2026-03-15')")

# Stub provider for testing (no real API calls)
class StubProvider < TextToSqlAssistant::Providers::Base
  attr_accessor :responses

  def initialize(**)
    super(api_key: "test", model: "test")
    @responses = []
    @call_count = 0
  end

  def complete(_system_prompt, _user_message)
    response = @responses[@call_count] || "No response configured"
    @call_count += 1
    response
  end
end

RSpec.configure do |config|
  config.before(:each) do
    TextToSqlAssistant.instance_variable_set(:@configuration, nil)
  end
end
