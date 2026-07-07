# frozen_string_literal: true

require "test_helper"

class ImportSessionTest < ActiveSupport::TestCase
  test "create_from_upload! stores session and returns import session" do
    file = file_fixture("contacts.csv")

    session = CsvDrop::ImportSession.create_from_upload!(file: file, model_name: "Contact")

    assert_equal "Contact", session.model_name
    assert_equal 2, session.row_count
    assert_equal %w[name email role], session.headers
  ensure
    CsvDrop::SessionStore.destroy(session.token) if session
  end

  test "fetch! raises when session is missing" do
    assert_raises(CsvDrop::Error) do
      CsvDrop::ImportSession.fetch!("missing-token")
    end
  end

  test "duplicate_options_from returns nils when key is blank" do
    options = CsvDrop::ImportSession.duplicate_options_from({ duplicate_key: "" })

    assert_nil options[:duplicate_key]
    assert_nil options[:duplicate_strategy]
  end

  test "create_from_upload! stores saved mapping when repeating" do
    source_id = CsvDrop::ImportProgressStore.create(
      model_name: "Contact",
      total_rows: 2,
      mapping: { "name" => "name", "email" => "email", "role" => "role" },
      status: "completed",
      duplicate_key: "email",
      duplicate_strategy: "update"
    )

    file = file_fixture("contacts.csv")
    session = CsvDrop::ImportSession.create_from_upload!(
      file: file,
      model_name: "Contact",
      repeat_from: source_id
    )

    assert_equal "email", session.mapping_context[:duplicate_key]
    assert_equal "update", session.mapping_context[:duplicate_strategy]
    assert_equal "name", session.suggested_mappings["name"]
    assert_equal "email", session.suggested_mappings["email"]
    assert_equal "role", session.suggested_mappings["role"]
  ensure
    CsvDrop::ImportProgressStore.destroy(source_id) if source_id
    CsvDrop::SessionStore.destroy(session.token) if session
  end
end
