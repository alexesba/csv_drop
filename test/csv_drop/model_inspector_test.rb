# frozen_string_literal: true

require "test_helper"

class ModelInspectorTest < ActiveSupport::TestCase
  test "duplicate_key_options includes configured, unique index, and likely key columns" do
    inspector = CsvDrop::ModelInspector.new(Contact)

    assert_includes inspector.duplicate_key_options, "email"
  end
end
