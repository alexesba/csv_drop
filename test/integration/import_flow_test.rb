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
    assert_equal "Alice", Contact.find_by!(email: "alice@example.com").name
    assert_equal "user", Contact.find_by!(email: "bob@example.com").role
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
    assert_includes result.errors.first.messages.join, "can't be blank"
  end
end
