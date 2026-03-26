# frozen_string_literal: true

require "spec_helper"

RSpec.describe TextToSqlAssistant::QueryValidator do
  let(:config) { TextToSqlAssistant::Configuration.new }
  let(:validator) { described_class.new(config) }

  describe "#validate!" do
    it "allows valid SELECT queries" do
      sql = validator.validate!("SELECT * FROM users")
      expect(sql).to start_with("SELECT")
    end

    it "rejects INSERT" do
      expect { validator.validate!("INSERT INTO users VALUES (1)") }
        .to raise_error(TextToSqlAssistant::QueryBlockedError, /Only SELECT/)
    end

    it "rejects UPDATE" do
      expect { validator.validate!("UPDATE users SET archived = 1") }
        .to raise_error(TextToSqlAssistant::QueryBlockedError, /Only SELECT/)
    end

    it "rejects DELETE" do
      expect { validator.validate!("DELETE FROM users") }
        .to raise_error(TextToSqlAssistant::QueryBlockedError, /Only SELECT/)
    end

    it "rejects DROP" do
      expect { validator.validate!("SELECT 1; DROP TABLE users") }
        .to raise_error(TextToSqlAssistant::QueryBlockedError, /forbidden keyword/)
    end

    it "rejects TRUNCATE" do
      expect { validator.validate!("SELECT 1; TRUNCATE users") }
        .to raise_error(TextToSqlAssistant::QueryBlockedError, /forbidden keyword/)
    end

    it "allows deleted_at in WHERE clause" do
      sql = validator.validate!("SELECT * FROM users WHERE deleted_at IS NULL")
      expect(sql).to include("deleted_at")
    end

    it "blocks encrypted_password column" do
      expect { validator.validate!("SELECT encrypted_password FROM users") }
        .to raise_error(TextToSqlAssistant::QueryBlockedError, /sensitive column/)
    end

    it "blocks reset_password_token column" do
      expect { validator.validate!("SELECT reset_password_token FROM users") }
        .to raise_error(TextToSqlAssistant::QueryBlockedError, /sensitive column/)
    end

    it "blocks information_schema" do
      expect { validator.validate!("SELECT * FROM information_schema.tables") }
        .to raise_error(TextToSqlAssistant::QueryBlockedError, /blocked pattern/)
    end

    it "blocks INTO OUTFILE" do
      expect { validator.validate!("SELECT * FROM users INTO OUTFILE '/tmp/x'") }
        .to raise_error(TextToSqlAssistant::QueryBlockedError, /blocked pattern/)
    end

    it "adds LIMIT when missing" do
      sql = validator.validate!("SELECT * FROM users")
      expect(sql).to include("LIMIT 50")
    end

    it "preserves existing LIMIT" do
      sql = validator.validate!("SELECT * FROM users LIMIT 10")
      expect(sql).not_to include("LIMIT 50")
      expect(sql).to include("LIMIT 10")
    end

    it "strips trailing semicolons" do
      sql = validator.validate!("SELECT * FROM users;")
      expect(sql).not_to end_with(";")
    end
  end
end
