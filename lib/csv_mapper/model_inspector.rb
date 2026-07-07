# frozen_string_literal: true

module CsvMapper
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

    def importable_columns
      model_class.columns.reject do |column|
        CsvMapper.config.excluded_columns.map(&:to_s).include?(column.name)
      end
    end

    private

    def validate_importable!
      allowed = CsvMapper.config.resolve_importable_models
      return if allowed.include?(model_class)

      raise Error, "#{model_class.name} is not available for import"
    end
  end
end
