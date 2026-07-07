# frozen_string_literal: true

require "test_helper"
require "csv"

class RejectsExporterTest < ActiveSupport::TestCase
  RowResult = CsvDrop::Result::RowResult

  test "exports failed rows with mapped columns and errors" do
    rows = [
      RowResult.new(row_number: 2, status: :valid, values: { "name" => "Alice" }, messages: []),
      RowResult.new(
        row_number: 3,
        status: :failed,
        values: { "name" => "", "email" => "bad@example.com" },
        messages: ["Name can't be blank"]
      )
    ]

    csv = CsvDrop::RejectsExporter.to_csv(
      rows: rows,
      column_headers: %w[name email]
    )

    parsed = CSV.parse(csv, headers: true)
    assert_equal 1, parsed.size
    assert_equal "3", parsed[0]["row"]
    assert_equal "", parsed[0]["name"]
    assert_equal "bad@example.com", parsed[0]["email"]
    assert_includes parsed[0]["errors"], "can't be blank"
  end

  test "returns header only when there are no failed rows" do
    rows = [
      RowResult.new(row_number: 2, status: :imported, values: { "name" => "Alice" }, messages: [])
    ]

    csv = CsvDrop::RejectsExporter.to_csv(rows: rows, column_headers: %w[name])

    assert_equal "row,name,errors\n", csv
  end
end
