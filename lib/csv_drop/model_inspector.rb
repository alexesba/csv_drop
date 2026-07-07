# frozen_string_literal: true

module CsvDrop
  class ModelInspector
    attr_reader :model_class

    def initialize(model_class)
      @model_class = model_class.is_a?(String) ? model_class.constantize : model_class
      validate_importable!
    end

    def column_names
      importable_columns.map(&:name)
    end

    def columns_for_select
      importable_columns.map do |column|
        {
          name: column.name,
          type: column.type,
          null: column.null,
          required: !column.null && !column.default
        }
      end
    end

    def duplicate_key_options
      (
        CsvDrop.config.duplicate_keys_for(model_class) +
        unique_index_columns +
        likely_key_columns
      ).uniq.select { |name| column_names.include?(name) }
    end

    def importable_columns
      model_class.columns.reject do |column|
        CsvDrop.config.excluded_columns.map(&:to_s).include?(column.name)
      end
    end

    private

    LIKELY_KEY_NAMES = %w[email uuid slug sku code external_id username].freeze

    def likely_key_columns
      column_names.select do |name|
        normalized = name.downcase
        LIKELY_KEY_NAMES.include?(normalized) ||
          normalized.end_with?("_id", "_uuid", "_code", "_slug", "_sku")
      end
    end

    def unique_index_columns
      model_class.connection.indexes(model_class.table_name)
        .select(&:unique)
        .flat_map(&:columns)
        .select { |name| column_names.include?(name) }
        .uniq
    end

    def validate_importable!
      allowed = CsvDrop.config.resolve_importable_models
      return if allowed.include?(model_class)

      raise Error, "#{model_class.name} is not available for import"
    end
  end
end
