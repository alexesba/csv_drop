# frozen_string_literal: true

require "test_helper"

class ImporterDuplicateTest < ActiveSupport::TestCase
  setup do
    Contact.create!(name: "Alice Existing", email: "alice@example.com", role: "admin")
  end

  test "skip strategy skips duplicate rows" do
    rows = [
      { name: "Alice", email: "alice@example.com", role: "user" },
      { name: "Bob", email: "bob@example.com", role: "user" }
    ]
    mapping = { "name" => "name", "email" => "email", "role" => "role" }

    assert_difference "Contact.count", 1 do
      result = CsvDrop::Importer.new(
        Contact,
        mapping,
        duplicate_key: "email",
        duplicate_strategy: "skip"
      ).import(rows)

      assert_equal 1, result.imported_count
      assert_equal 1, result.skipped_count
      assert_equal "admin", Contact.find_by!(email: "alice@example.com").role
    end
  end

  test "update strategy updates duplicate rows" do
    rows = [{ name: "Alice Updated", email: "alice@example.com", role: "user" }]
    mapping = { "name" => "name", "email" => "email", "role" => "role" }

    assert_no_difference "Contact.count" do
      result = CsvDrop::Importer.new(
        Contact,
        mapping,
        duplicate_key: "email",
        duplicate_strategy: "update"
      ).import(rows)

      assert_equal 1, result.updated_count
      assert_equal "Alice Updated", Contact.find_by!(email: "alice@example.com").name
    end
  end

  test "fail strategy marks duplicate rows as failed" do
    rows = [{ name: "Alice", email: "alice@example.com", role: "user" }]
    mapping = { "name" => "name", "email" => "email", "role" => "role" }

    result = CsvDrop::Importer.new(
      Contact,
      mapping,
      duplicate_key: "email",
      duplicate_strategy: "fail"
    ).import(rows)

    assert_equal 1, result.failure_count
    assert_includes result.errors.first.messages.join, "Duplicate"
  end

  test "skip strategy skips within-file duplicate rows" do
    rows = [
      { name: "First", email: "shared@example.com", role: "user" },
      { name: "Second", email: "shared@example.com", role: "admin" }
    ]
    mapping = { "name" => "name", "email" => "email", "role" => "role" }

    assert_difference "Contact.count", 1 do
      result = CsvDrop::Importer.new(
        Contact,
        mapping,
        duplicate_key: "email",
        duplicate_strategy: "skip"
      ).import(rows)

      assert_equal 1, result.imported_count
      assert_equal 1, result.skipped_count
      assert_equal 0, result.failure_count
    end
  end
end
