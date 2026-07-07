# frozen_string_literal: true

require "test_helper"

class ImporterDryRunTest < ActiveSupport::TestCase
  test "dry_run validates rows without persisting records" do
    rows = [
      { name: "", email: "alice@example.com", role: "admin" },
      { name: "Bob", email: "bob@example.com", role: "user" }
    ]
    mapping = { "name" => "name", "email" => "email", "role" => "role" }

    assert_no_difference "Contact.count" do
      result = CsvDrop::Importer.new(Contact, mapping).dry_run(rows)

      assert_equal 1, result.success_count
      assert_equal 1, result.failure_count
      assert_equal :valid, result.rows.last.status
      assert_equal :failed, result.rows.first.status
    end
  end
end
