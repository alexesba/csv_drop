# frozen_string_literal: true

require "test_helper"

class AsyncImportFlowTest < ActionDispatch::IntegrationTest
  setup do
    @original_threshold = CsvDrop.config.async_row_threshold
    CsvDrop.config.async_row_threshold = 1
  end

  teardown do
    CsvDrop.config.async_row_threshold = @original_threshold
  end

  test "async import runs in background and creates records" do
    file = fixture_file_upload("contacts.csv", "text/csv")

    post "/csv_drop/imports/preview",
      params: { csv_file: file, model_name: "Contact" },
      as: :multipart

    assert_redirected_to %r{/imports/mapping}
    follow_redirect!

    token = response.body[/name="token"[^>]*value="([^"]+)"/, 1] ||
            response.body[/value="([^"]+)"[^>]*name="token"/, 1]

    assert_difference "Contact.count", 2 do
      post "/csv_drop/imports", params: {
        token: token,
        mapping: {
          "name" => "name",
          "email" => "email",
          "role" => "role"
        }
      }
    end

    assert_redirected_to %r{/imports/}
    import_id = response.redirect_url[%r{/imports/([^/?]+)}, 1]

    follow_redirect!
    assert_match "Import Complete", response.body

    progress = CsvDrop::ImportProgressStore.fetch(import_id)
    assert_equal "completed", progress[:status]
    assert_equal 2, progress[:success_count]
  end
end
