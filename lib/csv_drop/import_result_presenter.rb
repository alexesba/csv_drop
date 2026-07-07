# frozen_string_literal: true

module CsvDrop
  module ImportResultPresenter
    module_function

    def column_headers(mapping)
      mapping.each_with_object([]) do |(csv_col, attr), headers|
        next if skip_attribute?(attr)

        headers << csv_col.to_s
      end
    end

    def snapshot_from_result(result, mapping:)
      ResultSnapshot.new(
        total_rows: result.total_rows,
        success_count: result.success_count,
        failure_count: result.failure_count,
        errors: result.errors,
        rows: result.rows,
        column_headers: column_headers(mapping)
      )
    end

    def snapshot_from_progress(import)
      mapping = import[:mapping] || import["mapping"] || {}
      rows = rows_from_progress(import)

      ResultSnapshot.new(
        total_rows: import[:total_rows],
        success_count: import[:success_count],
        failure_count: import[:failure_count],
        errors: errors_from_rows(rows),
        rows: rows,
        column_headers: column_headers(mapping)
      )
    end

    def serialize_rows(result)
      result.rows.map { |row| serialize_row(row) }
    end

    def serialize_failed_rows(result)
      result.rows.select { |row| row.status == :failed }.map { |row| serialize_row(row) }
    end

    def live_failures_snapshot(import)
      mapping = import[:mapping] || import["mapping"] || {}
      rows = normalize_rows(import[:failed_rows] || import["failed_rows"] || [])

      ResultSnapshot.new(
        total_rows: rows.size,
        success_count: 0,
        failure_count: rows.size,
        errors: errors_from_rows(rows),
        rows: rows,
        column_headers: column_headers(mapping)
      )
    end

    def serialize_row(row)
      {
        row_number: row.row_number,
        status: row.status.to_s,
        values: row.values,
        messages: row.messages
      }
    end

    def rows_from_progress(import)
      raw_rows = import[:rows] || import["rows"]
      return normalize_rows(raw_rows) if raw_rows.present?

      legacy_rows_from_errors(import)
    end

    def normalize_rows(raw_rows)
      raw_rows.map do |row|
        Result::RowResult.new(
          row_number: row[:row_number] || row["row_number"],
          status: (row[:status] || row["status"]).to_sym,
          values: stringify_keys(row[:values] || row["values"] || {}),
          messages: row[:messages] || row["messages"] || []
        )
      end
    end

    def legacy_rows_from_errors(import)
      import.fetch(:errors, []).map do |error|
        Result::RowResult.new(
          row_number: error[:row_number] || error["row_number"],
          status: :failed,
          values: stringify_keys(error[:attributes] || error["attributes"] || {}),
          messages: error[:messages] || error["messages"] || []
        )
      end
    end

    def errors_from_rows(rows)
      rows.select { |row| row.status == :failed }.map do |row|
        Result::RowError.new(
          row_number: row.row_number,
          attributes: row.values,
          messages: row.messages
        )
      end
    end

    def skip_attribute?(attr)
      attr.nil? || attr == Mapper::SKIP || attr.to_s.empty?
    end

    def stringify_keys(hash)
      hash.each_with_object({}) do |(key, value), result|
        result[key.to_s] = value
      end
    end
  end
end
