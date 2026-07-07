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
end
