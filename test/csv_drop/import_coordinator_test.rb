# frozen_string_literal: true

require "test_helper"

class ImportCoordinatorTest < ActiveSupport::TestCase
  setup do
    file = file_fixture("contacts.csv")
    @session = CsvDrop::ImportSession.create_from_upload!(file: file, model_name: "Contact")
    @mapping = { "name" => "name", "email" => "email", "role" => "role" }
    @coordinator = CsvDrop::ImportCoordinator.new(
      session: @session,
      mapping: @mapping,
      duplicate_options: { duplicate_key: nil, duplicate_strategy: nil }
    )
  end

  teardown do
    CsvDrop::SessionStore.destroy(@session.token) if @session
  end

  test "start_sync! imports rows and destroys session" do
    import_id = nil

    assert_difference "Contact.count", 2 do
      import_id = @coordinator.start_sync!
      progress = CsvDrop::ImportProgressStore.fetch(import_id)

      assert_equal "completed", progress[:status]
      assert_equal 2, progress[:success_count]
    end

    assert_nil CsvDrop::SessionStore.fetch(@session.token)
  ensure
    CsvDrop::ImportProgressStore.destroy(import_id) if import_id
  end

  test "start_dry_run! validates without persisting" do
    import_id = nil

    assert_no_difference "Contact.count" do
      import_id = @coordinator.start_dry_run!
      progress = CsvDrop::ImportProgressStore.fetch(import_id)

      assert progress[:dry_run]
      assert_equal 2, progress[:success_count]
    end
  ensure
    CsvDrop::ImportProgressStore.destroy(import_id) if import_id
  end
end
