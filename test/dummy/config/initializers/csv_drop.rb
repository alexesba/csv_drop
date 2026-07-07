# frozen_string_literal: true

# Demo app configuration for ./bin/demo
CsvDrop.configure do |config|
  config.duplicate_keys = { "Contact" => %w[email] }
end
