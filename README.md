# CsvMapper

Zero-config CSV import for Rails. Install the gem, mount the engine, and import into **any** ActiveRecord model — no importer classes, no persistence targets, no DSL.

## Why this exists

Gems like [data_porter](https://github.com/SerylLns/data_porter) and [importance](https://github.com/code-fabrik/importance) require you to define import targets/importers with custom persistence logic. **CsvMapper** takes a different approach:

1. Install the gem
2. Upload a CSV
3. Pick any model from your app
4. Map columns to fields
5. Hit Import — records are saved via standard `ActiveRecord#create`

No configuration required.

## Features

- **Auto-discovers all ActiveRecord models** in your Rails app
- **Auto-loads model columns** when you select a target table
- Manual CSV column → field mapping (with auto-detect)
- Preview first 5 rows before importing
- Row-by-row `save` with validation error reporting
- Optional config only when you need to restrict models or columns

## Installation

```ruby
# Gemfile
gem "csv_mapper"
```

```bash
bundle install
rails generate csv_mapper:install
```

Visit `/csv_import`. That's it.

## User Flow

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐     ┌─────────────┐
│ Upload CSV  │ ──▶ │ Select Model │ ──▶ │ Map Columns │ ──▶ │   Import    │
│             │     │  (all models)│     │  to Fields  │     │ model.save  │
└─────────────┘     └──────────────┘     └─────────────┘     └─────────────┘
```

1. **Upload** — User selects a CSV file
2. **Select model** — Dropdown lists every ActiveRecord model in the app
3. **Map fields** — Each CSV column maps to a model attribute (or skip)
4. **Import** — Each row calls `Model.new(attrs).save` — validations and callbacks run normally

## Optional Configuration

Configuration is **not required**. Use it only to restrict behavior:

```ruby
# config/initializers/csv_mapper.rb
CsvMapper.configure do |config|
  # Limit which models appear (default: all models)
  config.importable_models = [User, Product]

  # Or exclude specific models
  config.excluded_models = ["ActiveStorage::Blob"]

  # Hide columns from mapping UI
  config.excluded_columns = %i[id created_at updated_at]

  # Cap rows per import
  config.max_rows = 10_000
end
```

## Programmatic API

```ruby
parsed = CsvMapper::Parser.parse("users.csv")
mapping = { "full_name" => "name", "email_address" => "email" }
result = CsvMapper::Importer.new(User, mapping).import(parsed.rows)

result.success_count  # => 48
result.failure_count  # => 2
result.errors         # => per-row validation failures
```

## Comparison

| | CsvMapper | data_porter | importance |
|---|---|---|---|
| Config required | No | Yes (targets DSL) | Yes (importers) |
| Model selection | All AR models | Pre-defined targets | Pre-defined importers |
| Persistence | `model.save` | Custom `persist` method | Custom importer logic |
| Column mapping UI | Yes | Yes | Yes |

## Roadmap

- [ ] **Dry run** — preview import results without saving
- [ ] Multi-model imports (associations)
- [ ] `insert_all` batch mode for large files
- [ ] Duplicate detection / upsert
- [ ] Background job support (ActiveJob)

## Development

```bash
cd csv_mapper
bundle install
bundle exec rake test
```

## License

MIT
