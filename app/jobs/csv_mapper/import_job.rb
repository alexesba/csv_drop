# frozen_string_literal: true

module CsvMapper
  class ImportJob < ApplicationJob
    queue_as :default

    def perform(import_id:, csv_path:, model_name:, mapping:, session_token:)
      progress = ImportProgressStore.update(import_id, status: "running")
      ImportBroadcaster.broadcast_progress(import_id, import: progress)

      parsed = Parser.parse(File.open(csv_path))
      importer = Importer.new(model_name, mapping)
      broadcast_every = CsvMapper.config.progress_broadcast_every

      result = importer.import(parsed.rows) do |stats|
        next unless stats[:processed_rows] % broadcast_every == 0 || stats[:processed_rows] == stats[:total_rows]

        updated = ImportProgressStore.update(import_id, stats)
        ImportBroadcaster.broadcast_progress(import_id, import: updated)
      end

      SessionStore.destroy(session_token)

      serialized_errors = result.errors.map do |error|
        {
          row_number: error.row_number,
          attributes: error.attributes,
          messages: error.messages
        }
      end

      ImportProgressStore.update(
        import_id,
        status: "completed",
        processed_rows: result.total_rows,
        success_count: result.success_count,
        failure_count: result.failure_count,
        errors: serialized_errors
      )

      ImportBroadcaster.broadcast_result(import_id, result: result, model_name: model_name)
    rescue Error => e
      progress = ImportProgressStore.update(import_id, status: "failed", error_message: e.message)
      ImportBroadcaster.broadcast_failure(import_id, import: progress)
      raise
    end
  end
end
