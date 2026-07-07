# frozen_string_literal: true

require "test_helper"

class ImportSessionDuplicateOptionsTest < ActiveSupport::TestCase
  test "duplicate_options_from normalizes strategy to a symbol" do
    options = CsvDrop::ImportSession.duplicate_options_from(
      duplicate_key: "email",
      duplicate_strategy: "skip"
    )

    assert_equal "email", options[:duplicate_key]
    assert_equal :skip, options[:duplicate_strategy]
  end

  test "duplicate_options_from defaults missing strategy to skip" do
    options = CsvDrop::ImportSession.duplicate_options_from(
      duplicate_key: "email"
    )

    assert_equal :skip, options[:duplicate_strategy]
  end
end
