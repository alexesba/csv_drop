# frozen_string_literal: true

module CsvMapper
  class Mapper
    SKIP = "_skip"

    # mapping: { csv_column: model_attribute_or_skip }
    def initialize(model_class, mapping)
      @model_class = model_class.is_a?(String) ? model_class.constantize : model_class
      @mapping = normalize_mapping(mapping)
      @columns_by_name = @model_class.columns.index_by(&:name)
    end

    def map_row(csv_row)
      attributes = {}

      @mapping.each do |csv_column, attribute|
        next if attribute.nil? || attribute == SKIP || attribute.to_s.empty?

        raw_value = csv_row[csv_column.to_sym] || csv_row[csv_column.to_s]
        attributes[attribute.to_s] = cast_value(attribute.to_s, raw_value)
      end

      attributes
    end

    def required_unmapped
      required = ModelInspector.new(@model_class).columns_for_select
        .select { |c| c[:required] }
        .map { |c| c[:name] }

      mapped = @mapping.values.reject { |v| v.nil? || v == SKIP || v.to_s.empty? }.map(&:to_s)
      required - mapped
    end

    private

    def normalize_mapping(mapping)
      mapping.each_with_object({}) do |(csv_col, attr), result|
        result[csv_col.to_s] = attr.to_s
      end
    end

    def cast_value(column_name, value)
      return nil if value.nil? || (value.is_a?(String) && value.strip.empty?)

      column = @columns_by_name[column_name]
      return value unless column

      case column.type
      when :integer, :bigint
        value.to_i
      when :float, :decimal
        value.to_f
      when :boolean
        %w[true 1 yes t y].include?(value.to_s.downcase)
      when :date
        Date.parse(value.to_s)
      when :datetime, :timestamp
        Time.zone.parse(value.to_s)
      else
        value.to_s.strip
      end
    rescue ArgumentError, TypeError
      value
    end
  end
end
