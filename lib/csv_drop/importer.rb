# frozen_string_literal: true

module CsvDrop
  class Importer
    def initialize(model_class, mapping, duplicate_key: nil, duplicate_strategy: nil)
      @model_class = model_class.is_a?(String) ? model_class.constantize : model_class
      @mapper = Mapper.new(@model_class, mapping)
      @duplicate_resolver = DuplicateResolver.new(model_class: @model_class, key: duplicate_key)
      @duplicate_strategy = if @duplicate_resolver.enabled?
                              DuplicateResolver.normalize_strategy(
                                duplicate_strategy || CsvDrop.config.default_duplicate_strategy
                              )
                            end
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
      validate_duplicate_key!

      result = Result.new(total_rows: rows.size)
      max_rows = CsvDrop.config.max_rows

      rows.each_with_index do |row, index|
        break if max_rows && index >= max_rows

        row_number = index + 2 # header is row 1
        display_values = @mapper.row_values(row)
        attributes = @mapper.map_row(row)

        process_row(
          result: result,
          row_number: row_number,
          display_values: display_values,
          attributes: attributes,
          persist: persist
        )

        emit_progress(progress, result, index + 1, rows.size)
      end

      result
    end

    def process_row(result:, row_number:, display_values:, attributes:, persist:)
      existing = @duplicate_resolver.find_existing(attributes) if @duplicate_resolver.enabled?

      if existing
        handle_duplicate(
          result: result,
          row_number: row_number,
          display_values: display_values,
          attributes: attributes,
          existing: existing,
          persist: persist
        )
      else
        create_row(
          result: result,
          row_number: row_number,
          display_values: display_values,
          attributes: attributes,
          persist: persist
        )
      end
    end

    def handle_duplicate(result:, row_number:, display_values:, attributes:, existing:, persist:)
      case @duplicate_strategy
      when :skip
        result.add_row(
          row_number: row_number,
          status: :skipped,
          values: display_values,
          messages: [@duplicate_resolver.duplicate_message]
        )
      when :fail
        result.add_row(
          row_number: row_number,
          status: :failed,
          values: display_values,
          messages: [@duplicate_resolver.duplicate_message]
        )
      when :update
        update_row(
          result: result,
          row_number: row_number,
          display_values: display_values,
          attributes: attributes,
          record: existing,
          persist: persist
        )
      end
    end

    def create_row(result:, row_number:, display_values:, attributes:, persist:)
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
      end
    end

    def update_row(result:, row_number:, display_values:, attributes:, record:, persist:)
      record.assign_attributes(attributes)

      if persist
        if record.save
          result.add_row(row_number: row_number, status: :updated, values: display_values)
        else
          result.add_row(
            row_number: row_number,
            status: :failed,
            values: display_values,
            messages: record.errors.full_messages
          )
        end
      elsif record.valid?
        result.add_row(row_number: row_number, status: :valid, values: display_values)
      else
        result.add_row(
          row_number: row_number,
          status: :failed,
          values: display_values,
          messages: record.errors.full_messages
        )
      end
    end

    def validate_mapping!
      unmapped = @mapper.required_unmapped
      return if unmapped.empty?

      raise Error, "Required columns not mapped: #{unmapped.join(', ')}"
    end

    def validate_duplicate_key!
      return unless @duplicate_resolver.enabled?

      key = @duplicate_resolver.key
      return if @mapper.mapped_attributes.include?(key)

      raise Error, "Duplicate key column \"#{key}\" must be mapped"
    end

    def emit_progress(callback, result, processed_rows, total_rows)
      return unless callback

      callback.call(
        processed_rows: processed_rows,
        total_rows: total_rows,
        success_count: result.success_count,
        failure_count: result.failure_count,
        skipped_count: result.skipped_count,
        updated_count: result.updated_count
      )
    end
  end
end
