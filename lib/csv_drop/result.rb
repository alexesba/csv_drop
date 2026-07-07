# frozen_string_literal: true

module CsvDrop
  class Result
    RowError = Data.define(:row_number, :attributes, :messages)

    attr_reader :created_records, :errors, :total_rows

    def initialize(total_rows:)
      @total_rows = total_rows
      @created_records = []
      @errors = []
    end

    def success_count
      @created_records.size
    end

    def failure_count
      @errors.size
    end

    def success?
      @errors.empty?
    end

    def add_success(record)
      @created_records << record
    end

    def add_error(row_number:, attributes:, messages:)
      @errors << RowError.new(row_number: row_number, attributes: attributes, messages: messages)
    end
  end
end
