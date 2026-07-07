# CsvDrop

Zero-config CSV import for Rails. Install the gem, mount the engine, and import into **any** ActiveRecord model — no importer classes, no persistence targets, no DSL.

## Why this exists

Gems like [data_porter](https://github.com/SerylLns/data_porter) and [importance](https://github.com/code-fabrik/importance) require you to define import targets/importers with custom persistence logic. **CsvDrop** takes a different approach:

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
- Background imports with Turbo Frame progress for large files
- Optional config only when you need to restrict models or columns

## Installation

```ruby
# Gemfile
gem "csv_drop"
```

```bash
bundle install
rails generate csv_drop:install
```

Visit `/csv_drop`. That's it.

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
# config/initializers/csv_drop.rb
CsvDrop.configure do |config|
  # Limit which models appear (default: all models)
  config.importable_models = [User, Product]

  # Or exclude specific models
  config.excluded_models = ["ActiveStorage::Blob"]

  # Hide columns from mapping UI
  config.excluded_columns = %i[id created_at updated_at]

  # Cap rows per import
  config.max_rows = 10_000

  # Async imports for large files (Turbo Frame progress UI)
  config.async_imports = true
  config.async_row_threshold = 50
  config.progress_broadcast_every = 10
end
```

## Async imports (Turbo Frames)

Imports at or above `async_row_threshold` rows are enqueued via `CsvDrop::ImportJob`. The UI shows a progress Turbo Frame that updates over Action Cable and swaps to the results view when complete.

Small imports (below the threshold) still run synchronously in the request.

Requires `turbo-rails`, Action Cable, and **importmap** (or an asset pipeline) in the host app:

```bash
bundle add turbo-rails importmap-rails propshaft
rails importmap:install
rails turbo:install
```

## Storage backends (Heroku / multi-dyno)

By default, CsvDrop uses local disk under `/tmp` — fine for development and single-server deploys.

For **Heroku**, **Render**, or any environment with ephemeral or per-dyno filesystems, configure shared storage:

| Data | Default | Production |
|------|---------|------------|
| Uploaded CSV files | Disk (`/tmp`) | Active Storage (S3) |
| Import sessions | Disk | Redis |
| Import progress | Disk | Redis |

### Auto-detect (recommended)

Set `REDIS_URL` and configure Active Storage with S3. CsvDrop picks Redis + Active Storage automatically:

```ruby
# config/initializers/csv_drop.rb
CsvDrop.configure do |config|
  config.session_store = :auto   # Redis when REDIS_URL is set, else disk
  config.progress_store = :auto
  config.file_store = :auto      # Active Storage when available, else disk
end
```

Add the `redis` gem when using Redis backends:

```bash
bundle add redis
```

### Explicit configuration

```ruby
CsvDrop.configure do |config|
  config.session_store = :redis
  config.progress_store = :redis
  config.file_store = :active_storage
  config.redis = -> { Redis.new(url: ENV["REDIS_URL"]) }
  config.session_ttl = 1.hour
  config.progress_ttl = 24.hours
end
```

Use `:file` and `:disk` to force local storage (default behavior).

## Programmatic API

```ruby
parsed = CsvDrop::Parser.parse("users.csv")
mapping = { "full_name" => "name", "email_address" => "email" }
result = CsvDrop::Importer.new(User, mapping).import(parsed.rows)

result.success_count  # => 48
result.failure_count  # => 2
result.errors         # => per-row validation failures
```

## Comparison

| | CsvDrop | data_porter | importance |
|---|---|---|---|
| Config required | No | Yes (targets DSL) | Yes (importers) |
| Model selection | All AR models | Pre-defined targets | Pre-defined importers |
| Persistence | `model.save` | Custom `persist` method | Custom importer logic |
| Column mapping UI | Yes | Yes | Yes |

## Roadmap

- [ ] **Dry run** — preview import results without saving
- [x] **Turbo Frames + background jobs** — enqueue large imports, show progress, update UI on completion
- [x] **Pluggable storage backends** — Redis + Active Storage for Heroku/multi-dyno deploys
- [ ] Multi-model imports (associations)
- [ ] `insert_all` batch mode for large files
- [ ] Duplicate detection / upsert
- [ ] **Customizable UI** — extract inline CSS/JS into gem assets (vanilla ES modules + `data-*` hooks) so host apps can override views/styles without forking behavior

## Testing

### Automated tests

A dummy Rails app lives in `test/dummy` with a `Contact` model. Run:

```bash
./bin/test
```

This runs unit tests (parser) and integration tests (full HTTP import flow).

### Manual browser test

Start the demo app:

```bash
./bin/demo
```

Then open http://localhost:3000/csv_drop:

| File | Rows | Behavior |
|------|------|----------|
| `test/fixtures/files/contacts.csv` | 2 | Sync import (instant results) |
| `test/fixtures/files/contacts_large.csv` | 55 | Async import (Turbo progress UI) |

Upload into the **Contact** model and map `name`, `email`, `role`.

## Development

```bash
cd csv_drop
bundle install
bundle exec rake test
```

## License

MIT
