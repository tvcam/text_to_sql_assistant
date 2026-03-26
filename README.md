# TextToSqlAssistant

Ask your database questions in plain English. Get SQL queries and human-readable answers.

Works with **Anthropic Claude**, **OpenAI**, and **Google Gemini**. Zero dependencies beyond ActiveRecord and Ruby stdlib.

## Installation

```ruby
gem "text_to_sql_assistant"
```

## Quick Start

```ruby
TextToSqlAssistant.configure do |c|
  c.provider = :anthropic
  c.api_key = ENV["ANTHROPIC_API_KEY"]
end

assistant = TextToSqlAssistant.new(
  connection: ActiveRecord::Base.connection
)

result = assistant.ask("Who are the top 5 customers by order total?")
puts result[:answer]   # Human-readable explanation
puts result[:sql]      # Generated SELECT query
puts result[:results]  # First 10 rows
```

## How It Works

1. Auto-reads your database schema (tables, columns, types)
2. Sends schema + question to the LLM
3. LLM generates a SELECT query
4. Validates the query (SELECT-only, no sensitive columns, row limit)
5. Executes against your database
6. Sends results back to LLM for human-readable interpretation

Two LLM calls per question. ~$0.002 on Claude Haiku.

## Providers

### Anthropic Claude (default)

```ruby
TextToSqlAssistant.configure do |c|
  c.provider = :anthropic
  c.api_key = ENV["ANTHROPIC_API_KEY"]
  c.model = "claude-haiku-4-5-20251001"  # default, cheapest
end
```

### OpenAI

```ruby
TextToSqlAssistant.configure do |c|
  c.provider = :openai
  c.api_key = ENV["OPENAI_API_KEY"]
  c.model = "gpt-4o-mini"  # default
end
```

### Google Gemini

```ruby
TextToSqlAssistant.configure do |c|
  c.provider = :gemini
  c.api_key = ENV["GEMINI_API_KEY"]
  c.model = "gemini-2.0-flash"  # default
end
```

### Custom Provider

```ruby
class MyProvider < TextToSqlAssistant::Providers::Base
  def complete(system_prompt, user_message)
    # Call your LLM, return the response text
  end
end

assistant = TextToSqlAssistant.new(provider: MyProvider)
```

## Configuration

```ruby
TextToSqlAssistant.configure do |c|
  c.provider = :anthropic
  c.api_key = ENV["ANTHROPIC_API_KEY"]
  c.model = "claude-haiku-4-5-20251001"
  c.max_rows = 50                    # LIMIT enforced on all queries
  c.query_timeout = 5                # seconds
  c.log_queries = true               # log to Rails.logger
  c.blocked_columns = %w[            # reject queries touching these
    encrypted_password
    reset_password_token
    api_secret
  ]
  c.blocked_tables = %w[             # excluded from schema
    information_schema
  ]
  c.on_query = ->(question, result) { # audit callback
    AuditLog.create!(query: question, sql: result[:sql])
  }
end
```

## Custom Schema

By default, the gem reads your database schema automatically. You can override this with a custom description for better LLM accuracy:

```ruby
assistant = TextToSqlAssistant.new(
  schema: <<~SCHEMA
    - users: id, email, name, role(admin/member), created_at
    - orders: id, user_id, total_cents, status(pending/paid/refunded), created_at
    - products: id, name, price_cents, category, active(boolean)
    NOTE: orders.total_cents is in cents, divide by 100 for dollars.
    NOTE: users with role='admin' are internal, exclude from customer queries.
  SCHEMA
)
```

## Security

The gem blocks dangerous queries at the application level:

- **SELECT only** — rejects INSERT, UPDATE, DELETE, DROP, etc.
- **Column blocklist** — blocks `encrypted_password`, `reset_password_token`, etc.
- **Table blocklist** — excludes `information_schema` and system tables
- **Row limit** — forces LIMIT on all queries (default 50)
- **Query timeout** — kills slow queries (default 5 seconds)

**Important:** Application-level validation is defense in depth. For production, always use a **read-only database user**:

```sql
CREATE USER 'ai_readonly'@'%' IDENTIFIED BY '...';
GRANT SELECT ON your_database.* TO 'ai_readonly'@'%';
```

## Response Format

```ruby
result = assistant.ask("How many users signed up this month?")

result[:answer]      # "47 users signed up this month, up 12% from last month..."
result[:sql]         # "SELECT COUNT(*) FROM users WHERE created_at >= '2026-03-01'"
result[:results]     # [{"count" => 47}]  (first 10 rows)
result[:total_rows]  # 1
result[:duration_ms] # 3241.5
```

## Requirements

- Ruby >= 3.1
- ActiveRecord >= 7.0
- An API key for Anthropic, OpenAI, or Google Gemini

## License

MIT
