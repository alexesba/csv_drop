# frozen_string_literal: true

require "test_helper"

class MapperTest < ActiveSupport::TestCase
  MODEL_COLUMNS = [
    { name: "name", type: :string, null: false, required: true },
    { name: "email", type: :string, null: true, required: false },
    { name: "role", type: :string, null: true, required: false }
  ].freeze

  test "auto_detect_attribute matches headers case-insensitively" do
    assert_equal "email", CsvDrop::Mapper.auto_detect_attribute("Email", MODEL_COLUMNS)
    assert_equal "name", CsvDrop::Mapper.auto_detect_attribute("NAME", MODEL_COLUMNS)
    assert_nil CsvDrop::Mapper.auto_detect_attribute("unknown", MODEL_COLUMNS)
  end

  test "auto_detect_attribute normalizes spaces and dashes" do
    columns = [{ name: "full_name" }]
    assert_equal "full_name", CsvDrop::Mapper.auto_detect_attribute("Full Name", columns)
    assert_equal "full_name", CsvDrop::Mapper.auto_detect_attribute("full-name", columns)
  end

  test "resolve_mapping fills blank values from auto-detect" do
    mapping = CsvDrop::Mapper.resolve_mapping(
      { "name" => "", "email" => "", "role" => "" },
      %w[name email role],
      MODEL_COLUMNS
    )

    assert_equal({ "name" => "name", "email" => "email", "role" => "role" }, mapping)
  end

  test "resolve_mapping preserves explicit skip and mapping choices" do
    mapping = CsvDrop::Mapper.resolve_mapping(
      { "name" => "name", "email" => CsvDrop::Mapper::SKIP, "notes" => "role" },
      %w[name email notes],
      MODEL_COLUMNS
    )

    assert_equal "name", mapping["name"]
    assert_equal CsvDrop::Mapper::SKIP, mapping["email"]
    assert_equal "role", mapping["notes"]
  end
end
