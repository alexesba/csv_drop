# frozen_string_literal: true

module CsvDrop
  class Result
    RowError = Data.define(:row_number, :attributes, :messages)
    RowResult = Data.define(:row_number, :status, :values, :messages)

    attr_reader :rows, :total_rows

    def initialize(total_rows:)
      @total_rows = total_rows
      @rows = []
    end

    def success_count
      @rows.count { |row| row.status == :imported }
    end

    def failure_count
      @rows.count { |row| row.status == :failed }
    end

    def errors
      @rows.select { |row| row.status == :failed }.map do |row|
        RowError.new(
          row_number: row.row_number,
          attributes: row.values,
          messages: row.messages
        )
      end
    end

    def success?
      failure_count.zero?
    end

    def add_row(row_number:, status:, values:, messages: [])
      @rows << RowResult.new(
        row_number: row_number,
        status: status,
        values: values,
        messages: messages
      )
    end
  end
end
