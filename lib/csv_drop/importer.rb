# frozen_string_literal: true

module CsvDrop
  class Importer
    def initialize(model_class, mapping)
      @model_class = model_class.is_a?(String) ? model_class.constantize : model_class
      @mapper = Mapper.new(@model_class, mapping)
    end

    def import(rows, &progress)
      run(rows, persist: true, &progress)
    end

    def dry_run(rows, &progress)
      run(rows, persist: false, &progress)
    end

    def dry_run_from_io(io)
      parsed = Parser.parse(io)
      dry_run(parsed.rows)
    end

    def import_from_file(path)
      import_from_io(File.open(path))
    end

    def import_from_io(io)
      parsed = Parser.parse(io)
      import(parsed.rows)
    end

    private

    def run(rows, persist:, &progress)
      validate_mapping!

      result = Result.new(total_rows: rows.size)
      max_rows = CsvDrop.config.max_rows

      rows.each_with_index do |row, index|
        break if max_rows && index >= max_rows

        row_number = index + 2 # header is row 1
        display_values = @mapper.row_values(row)
        attributes = @mapper.map_row(row)
        failure_added = false

        record = @model_class.new(attributes)
        success = persist ? record.save : record.valid?

        if success
          result.add_row(
            row_number: row_number,
            status: persist ? :imported : :valid,
            values: display_values
          )
        else
          result.add_row(
            row_number: row_number,
            status: :failed,
            values: display_values,
            messages: record.errors.full_messages
          )
          failure_added = true
        end

        emit_progress(
          progress,
          result,
          index + 1,
          rows.size,
          persist: persist,
          failure_added: failure_added
        )
      end

      result
    end

    def validate_mapping!
      unmapped = @mapper.required_unmapped
      return if unmapped.empty?

      raise Error, "Required columns not mapped: #{unmapped.join(', ')}"
    end

    def emit_progress(callback, result, processed_rows, total_rows, persist:, failure_added: false)
      return unless callback

      payload = {
        processed_rows: processed_rows,
        total_rows: total_rows,
        success_count: result.success_count,
        failure_count: result.failure_count,
        failure_added: failure_added
      }

      if persist && CsvDrop.config.live_failures_during_import
        payload[:failed_rows] = ImportResultPresenter.serialize_failed_rows(result)
      end

      callback.call(payload)
    end
  end
end
