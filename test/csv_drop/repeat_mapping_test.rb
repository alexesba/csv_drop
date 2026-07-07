# frozen_string_literal: true

require "test_helper"

class RepeatMappingTest < ActiveSupport::TestCase
  test "loads mapping template from completed import" do
    import_id = CsvDrop::ImportProgressStore.create(
      model_name: "Contact",
      total_rows: 2,
      mapping: { "name" => "name", "email" => "email" },
      status: "completed",
      duplicate_key: "email",
      duplicate_strategy: "skip"
    )

    repeat = CsvDrop::RepeatMapping.from_import(import_id)

    assert_equal "Contact", repeat.model_name
    assert_equal "name", repeat.mapping["name"]
    assert_equal "email", repeat.duplicate_key
    assert_equal "skip", repeat.duplicate_strategy
  ensure
    CsvDrop::ImportProgressStore.destroy(import_id) if import_id
  end

  test "returns nil for incomplete imports" do
    import_id = CsvDrop::ImportProgressStore.create(
      model_name: "Contact",
      total_rows: 2,
      mapping: { "name" => "name" },
      status: "running"
    )

    assert_nil CsvDrop::RepeatMapping.from_import(import_id)
  ensure
    CsvDrop::ImportProgressStore.destroy(import_id) if import_id
  end

  test "mapping_for_header falls back to auto-detect for new columns" do
    repeat = CsvDrop::RepeatMapping.new(
      import_id: "abc",
      model_name: "Contact",
      mapping: { "name" => "name" }
    )

    columns = CsvDrop::ModelInspector.new(Contact).columns_for_select

    assert_equal "name", repeat.mapping_for_header("name", model_columns: columns)
    assert_equal "email", repeat.mapping_for_header("email", model_columns: columns)
  end
end
