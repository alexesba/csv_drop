# frozen_string_literal: true

require "test_helper"

class ImporterLiveFailuresTest < ActiveSupport::TestCase
  test "progress callback includes failed_rows for async-style imports" do
    rows = [
      { name: "", email: "alice@example.com", role: "admin" },
      { name: "Bob", email: "bob@example.com", role: "user" }
    ]
    mapping = { "name" => "name", "email" => "email", "role" => "role" }
    payloads = []

    CsvDrop::Importer.new(Contact, mapping).import(rows) { |payload| payloads << payload }

    failure_payload = payloads.find { |payload| payload[:failed_rows]&.any? }

    assert_equal 1, failure_payload[:failed_rows].size
    assert_equal "failed", failure_payload[:failed_rows].first[:status]
    assert payloads.any? { |payload| payload[:failure_added] }
  end

  test "dry run does not include failed_rows in progress payload" do
    rows = [{ name: "", email: "alice@example.com", role: "admin" }]
    mapping = { "name" => "name", "email" => "email", "role" => "role" }
    stats = nil

    CsvDrop::Importer.new(Contact, mapping).dry_run(rows) { |payload| stats = payload }

    assert_nil stats[:failed_rows]
  end
end
