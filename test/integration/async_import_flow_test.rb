# frozen_string_literal: true

require "test_helper"

class AsyncImportFlowTest < ActionDispatch::IntegrationTest
  setup do
    @original_threshold = CsvMapper.config.async_row_threshold
    CsvMapper.config.async_row_threshold = 1
  end

  teardown do
    CsvMapper.config.async_row_threshold = @original_threshold
  end

  test "async import runs in background and creates records" do
    file = fixture_file_upload("contacts.csv", "text/csv")

    post "/csv_import/imports/preview",
      params: { csv_file: file, model_name: "Contact" },
      as: :multipart

    assert_redirected_to %r{/imports/mapping}
    follow_redirect!

    token = response.body[/name="token"[^>]*value="([^"]+)"/, 1] ||
            response.body[/value="([^"]+)"[^>]*name="token"/, 1]

    assert_difference "Contact.count", 2 do
      post "/csv_import/imports", params: {
        token: token,
        mapping: {
          "name" => "name",
          "email" => "email",
          "role" => "role"
        }
      }
    end

    assert_response :accepted
    assert_match "Importing", response.body

    import_id = response.body[/data-import-id="([^"]+)"/, 1]
    assert import_id, "expected import id on processing page"

    progress = CsvMapper::ImportProgressStore.fetch(import_id)
    assert_equal "completed", progress[:status]
    assert_equal 2, progress[:success_count]
  end
end
