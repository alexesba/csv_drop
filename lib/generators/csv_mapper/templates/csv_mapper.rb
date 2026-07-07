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
# end
