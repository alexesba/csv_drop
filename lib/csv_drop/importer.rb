# frozen_string_literal: true

module CsvDrop
  class Importer
    def initialize(model_class, mapping)
      @model_class = model_class.is_a?(String) ? model_class.constantize : model_class
      @mapper = Mapper.new(@model_class, mapping)
    end

    def import(rows, &progress)
      validate_mapping!

      result = Result.new(total_rows: rows.size)
      max_rows = CsvDrop.config.max_rows

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

        emit_progress(progress, result, index + 1, rows.size)
      end

      result
    end

    def import_from_file(path)
      import_from_io(File.open(path))
    end

    def import_from_io(io)
      parsed = Parser.parse(io)
      import(parsed.rows)
    end

    private

    def validate_mapping!
      unmapped = @mapper.required_unmapped
      return if unmapped.empty?

      raise Error, "Required columns not mapped: #{unmapped.join(', ')}"
    end

    def emit_progress(callback, result, processed_rows, total_rows)
      return unless callback

      callback.call(
        processed_rows: processed_rows,
        total_rows: total_rows,
        success_count: result.success_count,
        failure_count: result.failure_count
      )
    end
  end
end
