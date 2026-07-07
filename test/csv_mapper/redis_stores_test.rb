# frozen_string_literal: true

require "test_helper"
require "support/fake_redis"

class RedisProgressStoreTest < ActiveSupport::TestCase
  setup do
    @redis = FakeRedis.new
    @store = CsvMapper::Stores::RedisProgressStore.new(redis: @redis)
  end

  test "tracks import progress through completion" do
    import_id = @store.create(
      model_name: "Contact",
      total_rows: 10,
      mapping: { "name" => "name" }
    )

    progress = @store.fetch(import_id)
    assert_equal "queued", progress[:status]

    @store.update(import_id, status: "running", processed_rows: 5)
    progress = @store.fetch(import_id)
    assert_equal "running", progress[:status]
    assert_equal 5, progress[:processed_rows]

    @store.update(
      import_id,
      status: "completed",
      processed_rows: 10,
      success_count: 10
    )
    progress = @store.fetch(import_id)
    assert_equal "completed", progress[:status]
    assert_equal 10, progress[:success_count]
  ensure
    @store.destroy(import_id) if import_id
  end
end

class RedisSessionStoreTest < ActiveSupport::TestCase
  setup do
    @redis = FakeRedis.new
    @file_store = CsvMapper::Stores::DiskFileStore.new
    @store = CsvMapper::Stores::RedisSessionStore.new(file_store: @file_store, redis: @redis)
  end

  test "stores session metadata and file reference" do
    file = Tempfile.new(["contacts", ".csv"])
    file.write("name,email\nAlice,alice@example.com\n")
    file.rewind

    token = @store.create(
      file: file,
      model_name: "Contact",
      headers: %w[name email],
      row_count: 1
    )

    session = @store.fetch(token)
    assert_equal "Contact", session[:model_name]
    assert_equal 1, session[:row_count]
    assert_equal "disk", session[:file_ref][:backend]

    io = @file_store.open(session[:file_ref])
    assert_includes io.read, "Alice"
  ensure
    @store.destroy(token) if token
    file&.close
    file&.unlink
  end
end
