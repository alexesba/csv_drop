# frozen_string_literal: true

# CsvMapper works out of the box — no configuration required.
# All ActiveRecord models are listed automatically.
#
# Optional settings:

# CsvMapper.configure do |config|
#   # Restrict which models appear in the dropdown (default: all models)
#   # config.importable_models = [User, Product]
#
#   # Hide specific models from the dropdown
#   # config.excluded_models = ["ActiveStorage::Blob"]
#
#   # Hide columns from the mapping UI
#   # config.excluded_columns = %i[id created_at updated_at]
#
#   # Cap rows per import
#   # config.max_rows = 10_000
#
#   # Async imports for large files (Turbo Frame progress UI)
#   # config.async_imports = true
#   # config.async_row_threshold = 50
#   # config.progress_broadcast_every = 10
#
#   # Storage backends (:auto picks Redis + Active Storage in production)
#   # config.session_store = :auto
#   # config.progress_store = :auto
#   # config.file_store = :auto
#   # config.redis = -> { Redis.new(url: ENV["REDIS_URL"]) }
# end
