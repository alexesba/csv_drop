# frozen_string_literal: true

require "test_helper"

class ImportProgressStoreTest < ActiveSupport::TestCase
  test "tracks import progress through completion" do
    import_id = CsvMapper::ImportProgressStore.create(
      model_name: "Contact",
      total_rows: 10,
      mapping: { "name" => "name" }
    )

    progress = CsvMapper::ImportProgressStore.fetch(import_id)
    assert_equal "queued", progress[:status]

    CsvMapper::ImportProgressStore.update(import_id, status: "running", processed_rows: 5)
    progress = CsvMapper::ImportProgressStore.fetch(import_id)
    assert_equal "running", progress[:status]
    assert_equal 5, progress[:processed_rows]

    CsvMapper::ImportProgressStore.update(
      import_id,
      status: "completed",
      processed_rows: 10,
      success_count: 10
    )
    progress = CsvMapper::ImportProgressStore.fetch(import_id)
    assert_equal "completed", progress[:status]
    assert_equal 10, progress[:success_count]
  ensure
    CsvMapper::ImportProgressStore.destroy(import_id) if import_id
  end
end
