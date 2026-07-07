# frozen_string_literal: true

require "test_helper"

class ImportFlowTest < ActionDispatch::IntegrationTest
  test "import page lists auto-discovered models" do
    get "/csv_drop"
    assert_response :success
    assert_match "Contact", response.body
  end

  test "full csv import flow creates records" do
    file = fixture_file_upload("contacts.csv", "text/csv")

    post "/csv_drop/imports/preview",
      params: { csv_file: file, model_name: "Contact" },
      as: :multipart

    assert_redirected_to %r{/imports/mapping}
    follow_redirect!
    assert_response :success, -> { "mapping failed: #{flash[:alert]}" }
    assert_match "Map CSV Columns", response.body

    token = response.body[/name="token"[^>]*value="([^"]+)"/, 1] ||
            response.body[/value="([^"]+)"[^>]*name="token"/, 1]
    assert token, "expected import session token in preview response"

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
    follow_redirect!
    assert_response :success
    assert_match "Import Complete", response.body
    assert_match "Import Results", response.body
    assert_match "Alice", response.body
    assert_match "bob@example.com", response.body
    assert_equal "Alice", Contact.find_by!(email: "alice@example.com").name
    assert_equal "user", Contact.find_by!(email: "bob@example.com").role
  end

  test "import results table shows validation failures with mapped columns" do
    file = fixture_file_upload("contacts_invalid.csv", "text/csv")

    post "/csv_drop/imports/preview",
      params: { csv_file: file, model_name: "Contact" },
      as: :multipart

    follow_redirect!

    token = response.body[/name="token"[^>]*value="([^"]+)"/, 1] ||
            response.body[/value="([^"]+)"[^>]*name="token"/, 1]

    assert_difference "Contact.count", 1 do
      post "/csv_drop/imports", params: {
        token: token,
        mapping: {
          "name" => "name",
          "email" => "email",
          "role" => "role"
        }
      }
    end

    follow_redirect!
    assert_match "Failed", response.body
    assert_match "be blank", response.body
    assert_match "alice@example.com", response.body
    assert_match "Bob", response.body
  end

  test "importer reports validation errors for invalid rows" do
    rows = [
      { name: "", email: "alice@example.com", role: "admin" },
      { name: "Bob", email: "bob@example.com", role: "user" }
    ]
    mapping = { "name" => "name", "email" => "email", "role" => "role" }

    result = CsvDrop::Importer.new(Contact, mapping).import(rows)

    assert_equal 1, result.success_count
    assert_equal 1, result.failure_count
    assert_equal 2, result.rows.size
    assert_equal :failed, result.rows.first.status
    assert_equal "alice@example.com", result.rows.first.values["email"]
    assert_includes result.errors.first.messages.join, "can't be blank"
  end

  test "dry run previews validation results without saving" do
    file = fixture_file_upload("contacts_invalid.csv", "text/csv")

    post "/csv_drop/imports/preview",
      params: { csv_file: file, model_name: "Contact" },
      as: :multipart

    follow_redirect!

    token = response.body[/name="token"[^>]*value="([^"]+)"/, 1] ||
            response.body[/value="([^"]+)"[^>]*name="token"/, 1]

    assert_no_difference "Contact.count" do
      post "/csv_drop/imports/dry_run", params: {
        token: token,
        mapping: {
          "name" => "name",
          "email" => "email",
          "role" => "role"
        }
      }
    end

    import_id = response.redirect_url[%r{/imports/([^/?]+)}, 1]
    follow_redirect!

    assert_match "Dry Run Complete", response.body
    assert_match "no records were saved", response.body
    assert_match "Valid", response.body
    assert_match "Import 2 Rows", response.body

    progress = CsvDrop::ImportProgressStore.fetch(import_id)
    assert progress[:dry_run]
    assert_equal token, progress[:session_token]
  end

  test "dry run confirm imports records" do
    file = fixture_file_upload("contacts_invalid.csv", "text/csv")

    post "/csv_drop/imports/preview",
      params: { csv_file: file, model_name: "Contact" },
      as: :multipart

    follow_redirect!

    token = response.body[/name="token"[^>]*value="([^"]+)"/, 1] ||
            response.body[/value="([^"]+)"[^>]*name="token"/, 1]

    post "/csv_drop/imports/dry_run", params: {
      token: token,
      mapping: { "name" => "name", "email" => "email", "role" => "role" }
    }

    follow_redirect!

    assert_difference "Contact.count", 1 do
      post "/csv_drop/imports", params: {
        token: token,
        mapping: { "name" => "name", "email" => "email", "role" => "role" }
      }
    end

    follow_redirect!
    assert_match "Import Complete", response.body
    refute_match "no records were saved", response.body
  end
end
