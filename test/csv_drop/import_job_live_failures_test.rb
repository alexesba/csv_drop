# frozen_string_literal: true

require "test_helper"

class ImportJobLiveFailuresTest < ActiveJob::TestCase
  test "completes async import with failures and stores full row results" do
    file = File.open(file_fixture("contacts_invalid.csv"))
    mapping = { "name" => "name", "email" => "email", "role" => "role" }

    token = CsvDrop::SessionStore.create(
      file: file,
      model_name: "Contact",
      headers: %w[name email role],
      row_count: 2
    )
    session = CsvDrop::SessionStore.fetch(token)

    import_id = CsvDrop::ImportProgressStore.create(
      model_name: "Contact",
      total_rows: 2,
      mapping: mapping
    )

    assert_difference "Contact.count", 1 do
      CsvDrop::ImportJob.perform_now(
        import_id: import_id,
        file_ref: session[:file_ref],
        model_name: "Contact",
        mapping: mapping,
        session_token: token
      )
    end

    progress = CsvDrop::ImportProgressStore.fetch(import_id)
    assert_equal "completed", progress[:status]
    assert_equal 1, progress[:failure_count]
    assert_equal 2, progress[:rows].size
    assert_equal [], progress[:failed_rows]
  ensure
    CsvDrop::ImportProgressStore.destroy(import_id) if import_id
    CsvDrop::SessionStore.destroy(token) if token
  end
end
