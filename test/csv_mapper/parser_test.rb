# frozen_string_literal: true

require "test_helper"
require "csv_mapper/parser"

class ParserTest < ActiveSupport::TestCase
  def test_parses_headers_and_rows
    csv = <<~CSV
      name,email,age
      Alice,alice@example.com,30
      Bob,bob@example.com,25
    CSV

    parsed = CsvMapper::Parser.parse(StringIO.new(csv))

    assert_equal %i[name email age], parsed.headers
    assert_equal 2, parsed.row_count
    assert_equal "Alice", parsed.rows.first[:name]
    assert_equal 2, parsed.preview_rows.size
  end
end
