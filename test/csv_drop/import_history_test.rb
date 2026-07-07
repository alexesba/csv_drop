# frozen_string_literal: true

require "test_helper"

class ImportHistoryTest < ActiveSupport::TestCase
  test "entries returns recent imports newest first" do
    older_id = CsvDrop::ImportProgressStore.create(
      model_name: "Contact",
      total_rows: 1,
      mapping: { "name" => "name" },
      status: "completed",
      success_count: 1
    )
    CsvDrop::ImportProgressStore.update(older_id, created_at: 1.hour.ago.to_i)

    newer_id = CsvDrop::ImportProgressStore.create(
      model_name: "Contact",
      total_rows: 2,
      mapping: { "name" => "name" },
      status: "completed",
      success_count: 2
    )
    CsvDrop::ImportProgressStore.update(newer_id, created_at: Time.now.to_i)

    entries = CsvDrop::ImportHistory.entries
    relevant = entries.select { |entry| [older_id, newer_id].include?(entry.id) }
    assert_equal 2, relevant.size
    assert_equal newer_id, relevant.first.id
    assert_equal 2, relevant.first.success_count
  ensure
    CsvDrop::ImportProgressStore.destroy(older_id) if older_id
    CsvDrop::ImportProgressStore.destroy(newer_id) if newer_id
  end

  test "label_for distinguishes dry runs" do
    entry = CsvDrop::ImportHistory.entry_from(
      id: "x",
      model_name: "Contact",
      status: "completed",
      dry_run: true,
      total_rows: 3,
      success_count: 3
    )

    assert_equal "Dry run", CsvDrop::ImportHistory.label_for(entry)
  end
end
