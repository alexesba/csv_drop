# frozen_string_literal: true

module CsvDrop
  ResultSnapshot = Data.define(:total_rows, :success_count, :failure_count, :errors, :rows, :column_headers) do
    def success?
      failure_count.zero?
    end

    def imported_count
      rows.count { |row| row.status == :imported }
    end

    def updated_count
      rows.count { |row| row.status == :updated }
    end

    def skipped_count
      rows.count { |row| row.status == :skipped }
    end
  end
end
