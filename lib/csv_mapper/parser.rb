# frozen_string_literal: true

require "csv"

module CsvMapper
  class Parser
    PREVIEW_ROW_LIMIT = 5

    attr_reader :headers, :rows, :preview_rows

    def self.parse(io_or_path)
      new(io_or_path).parse
    end

    def initialize(io_or_path)
      @source = io_or_path
    end

    def parse
      csv = CSV.new(@source, headers: true, header_converters: :symbol, liberal_parsing: true)
      @headers = []
      @rows = []

      csv.each do |row|
        @headers = row.headers if @headers.empty?
        @rows << row.to_h
      end

      @preview_rows = @rows.first(PREVIEW_ROW_LIMIT)
      self
    end

    def row_count
      @rows.size
    end
  end
end
