# frozen_string_literal: true

require "test_helper"

class ImportResultsTest < ActiveSupport::TestCase
  RowResult = CsvDrop::Result::RowResult

  def build_rows(count)
    (1..count).map do |n|
      RowResult.new(
        row_number: n + 1,
        status: :imported,
        values: { "name" => "User #{n}" },
        messages: []
      )
    end
  end

  test "paginates rows with default page size" do
    results = CsvDrop::ImportResults.new(rows: build_rows(120), page: 1)

    assert_equal 50, results.items.size
    assert_equal 3, results.total_pages
    assert_equal 1, results.current_page
  end

  test "returns requested page" do
    results = CsvDrop::ImportResults.new(rows: build_rows(120), page: 2)

    assert_equal 50, results.items.size
    assert_equal 2, results.current_page
    assert_equal 52, results.items.first.row_number
  end

  test "clamps page to last page" do
    results = CsvDrop::ImportResults.new(rows: build_rows(120), page: 99)

    assert_equal 3, results.current_page
    assert_equal 20, results.items.size
  end

  test "page_sequence shows first pages and last page on page 1" do
    results = CsvDrop::ImportResults.new(rows: build_rows(500), page: 1)

    assert_equal [1, 2, 3, 4, :gap, 10], results.page_sequence
  end

  test "page_sequence shows window around current page" do
    results = CsvDrop::ImportResults.new(rows: build_rows(500), page: 5)

    assert_equal [1, 2, 3, 4, 5, 6, 7, 8, :gap, 10], results.page_sequence
  end

  test "page_sequence shows gaps on both sides in the middle" do
    results = CsvDrop::ImportResults.new(rows: build_rows(2500), page: 25)

    assert_equal [1, :gap, 22, 23, 24, 25, 26, 27, 28, :gap, 50], results.page_sequence
  end

  test "page_sequence shows trailing pages near the end" do
    results = CsvDrop::ImportResults.new(rows: build_rows(500), page: 10)

    assert_equal [1, :gap, 7, 8, 9, 10], results.page_sequence
  end
end
