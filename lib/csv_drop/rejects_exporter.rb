# frozen_string_literal: true

require "csv"

module CsvDrop
  class RejectsExporter
    def self.to_csv(rows:, column_headers:, include_row_number: true)
      new(rows: rows, column_headers: column_headers, include_row_number: include_row_number).to_csv
    end

    def initialize(rows:, column_headers:, include_row_number: true)
      @rows = rows.select { |row| row.status == :failed }
      @column_headers = column_headers
      @include_row_number = include_row_number
    end

    def to_csv
      CSV.generate do |csv|
        csv << headers
        @rows.each { |row| csv << row_to_line(row) }
      end
    end

    private

    def headers
      list = []
      list << "row" if @include_row_number
      list + @column_headers + ["errors"]
    end

    def row_to_line(row)
      line = []
      line << row.row_number if @include_row_number
      @column_headers.each { |header| line << row.values[header] }
      line << row.messages.join("; ")
      line
    end
  end
end
