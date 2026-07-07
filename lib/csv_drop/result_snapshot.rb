# frozen_string_literal: true

module CsvDrop
  ResultSnapshot = Data.define(:total_rows, :success_count, :failure_count, :errors) do
    def success?
      failure_count.zero?
    end
  end
end
