# frozen_string_literal: true

require "test_helper"

class ImportResultPresenterTest < ActiveSupport::TestCase
  test "column_headers excludes skipped columns" do
    mapping = { "name" => "name", "notes" => CsvDrop::Mapper::SKIP, "email" => "email" }

    headers = CsvDrop::ImportResultPresenter.column_headers(mapping)

    assert_equal %w[name email], headers
  end

  test "snapshot_from_result includes mapped row values" do
    result = CsvDrop::Result.new(total_rows: 1)
    result.add_row(
      row_number: 2,
      status: :imported,
      values: { "name" => "Alice", "email" => "alice@example.com" }
    )

    snapshot = CsvDrop::ImportResultPresenter.snapshot_from_result(
      result,
      mapping: { "name" => "name", "email" => "email" }
    )

    assert_equal 1, snapshot.success_count
    assert_equal %w[name email], snapshot.column_headers
    assert_equal "Alice", snapshot.rows.first.values["name"]
  end

  test "snapshot_from_progress falls back to legacy errors" do
    import = {
      total_rows: 1,
      success_count: 0,
      failure_count: 1,
      mapping: { "name" => "name" },
      errors: [
        {
          row_number: 2,
          attributes: { "name" => "" },
          messages: ["Name can't be blank"]
        }
      ]
    }

    snapshot = CsvDrop::ImportResultPresenter.snapshot_from_progress(import)

    assert_equal 1, snapshot.rows.size
    assert_equal :failed, snapshot.rows.first.status
    assert_includes snapshot.errors.first.messages.join, "can't be blank"
  end

  test "live_failures_snapshot reads failed_rows from import progress" do
    import = {
      mapping: { "name" => "name", "email" => "email" },
      failed_rows: [
        {
          row_number: 2,
          status: "failed",
          values: { "name" => "", "email" => "alice@example.com" },
          messages: ["Name can't be blank"]
        }
      ]
    }

    snapshot = CsvDrop::ImportResultPresenter.live_failures_snapshot(import)

    assert_equal %w[name email], snapshot.column_headers
    assert_equal 1, snapshot.rows.size
    assert_equal :failed, snapshot.rows.first.status
  end
end
