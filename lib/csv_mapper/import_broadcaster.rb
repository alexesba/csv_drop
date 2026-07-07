# frozen_string_literal: true

module CsvMapper
  class ImportBroadcaster
    FRAME_ID = "csv_mapper_import_status"

    class << self
      def stream_name(import_id)
        "csv_mapper_import_#{import_id}"
      end

      def broadcast_progress(import_id, import:)
        broadcast_replace(
          import_id,
          partial: "csv_mapper/imports/progress",
          locals: { import: import }
        )
      end

      def broadcast_result(import_id, result:, model_name:)
        broadcast_replace(
          import_id,
          partial: "csv_mapper/imports/result_content",
          locals: { result: result, model_name: model_name }
        )
      end

      def broadcast_failure(import_id, import:)
        broadcast_replace(
          import_id,
          partial: "csv_mapper/imports/failed",
          locals: { import: import }
        )
      end

      private

      def broadcast_replace(import_id, partial:, locals:)
        return unless turbo_available?

        html = CsvMapper::ApplicationController.render(
          partial: partial,
          locals: locals,
          layout: false
        )

        Turbo::StreamsChannel.broadcast_replace_to(
          stream_name(import_id),
          target: FRAME_ID,
          html: html
        )
      end

      def turbo_available?
        defined?(Turbo::StreamsChannel)
      end
    end
  end
end
