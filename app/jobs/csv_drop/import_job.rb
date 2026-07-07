# frozen_string_literal: true

require "stringio"

module CsvDrop
  class ImportJob < ApplicationJob
    queue_as :default

    def perform(import_id:, file_ref:, model_name:, mapping:, session_token:, duplicate_key: nil, duplicate_strategy: nil)
      progress = ImportProgressStore.update(import_id, status: "running")
      ImportBroadcaster.broadcast_progress(import_id, import: progress)

      io = CsvDrop.config.file_store_adapter.open(file_ref)
      io = StringIO.new(io) unless io.respond_to?(:rewind)

      parsed = Parser.parse(io)
      importer = Importer.new(
        model_name,
        mapping,
        duplicate_key: duplicate_key,
        duplicate_strategy: duplicate_strategy
      )
      broadcast_every = CsvDrop.config.progress_broadcast_every

      result = importer.import(parsed.rows) do |stats|
        next unless stats[:processed_rows] % broadcast_every == 0 || stats[:processed_rows] == stats[:total_rows]

        updated = ImportProgressStore.update(import_id, stats)
        ImportBroadcaster.broadcast_progress(import_id, import: updated)
      end

      SessionStore.destroy(session_token)

      snapshot = ImportResultPresenter.snapshot_from_result(result, mapping: mapping)

      progress = ImportProgressStore.update(
        import_id,
        status: "completed",
        processed_rows: result.total_rows,
        success_count: result.success_count,
        failure_count: result.failure_count,
        skipped_count: result.skipped_count,
        updated_count: result.updated_count,
        rows: ImportResultPresenter.serialize_rows(result)
      )

      ImportBroadcaster.broadcast_result(
        import_id,
        result: snapshot,
        model_name: model_name,
        duplicate_key: duplicate_key,
        duplicate_strategy: duplicate_strategy
      )
    rescue Error => e
      progress = ImportProgressStore.update(import_id, status: "failed", error_message: e.message)
      ImportBroadcaster.broadcast_failure(import_id, import: progress)
      raise
    end
  end
end
