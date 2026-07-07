# frozen_string_literal: true

require "test_helper"

class DuplicateResolverTest < ActiveSupport::TestCase
  test "finds existing record by configured key" do
    Contact.create!(name: "Alice", email: "alice@example.com")
    resolver = CsvDrop::DuplicateResolver.new(model_class: Contact, key: "email")

    existing = resolver.find_existing("email" => "alice@example.com")

    assert_equal "Alice", existing.name
    assert_nil resolver.find_existing("email" => "missing@example.com")
  end

  test "normalizes duplicate strategy" do
    assert_equal :skip, CsvDrop::DuplicateResolver.normalize_strategy("skip")
    assert_equal :skip, CsvDrop::DuplicateResolver.normalize_strategy(nil)

    assert_raises(CsvDrop::Error) do
      CsvDrop::DuplicateResolver.normalize_strategy("invalid")
    end
  end
end
