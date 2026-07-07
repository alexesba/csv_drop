# frozen_string_literal: true

module CsvMapper
  class Importer
    def initialize(model_class, mapping)
      @model_class = model_class.is_a?(String) ? model_class.constantize : model_class
      @mapper = Mapper.new(@model_class, mapping)
    end

    def import(rows)
      validate_mapping!

      result = Result.new(total_rows: rows.size)
      max_rows = CsvMapper.config.max_rows

      rows.each_with_index do |row, index|
        break if max_rows && index >= max_rows

        row_number = index + 2 # header is row 1
        attributes = @mapper.map_row(row)

        record = @model_class.new(attributes)
        if record.save
          result.add_success(record)
        else
          result.add_error(
            row_number: row_number,
            attributes: attributes,
            messages: record.errors.full_messages
          )
        end
      end

      result
    end

    def import_from_file(path)
      parsed = Parser.parse(File.open(path))
      import(parsed.rows)
    end

    private

    def validate_mapping!
      unmapped = @mapper.required_unmapped
      return if unmapped.empty?

      raise Error, "Required columns not mapped: #{unmapped.join(', ')}"
    end
  end
end
