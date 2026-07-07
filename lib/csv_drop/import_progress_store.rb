# frozen_string_literal: true

module CsvDrop
  class ImportProgressStore
    STATUSES = Stores::FileProgressStore::STATUSES

    class << self
      def create(model_name:, total_rows:, mapping:, **attrs)
        adapter.create(
          model_name: model_name,
          total_rows: total_rows,
          mapping: mapping,
          **attrs
        )
      end

      def fetch(id)
        adapter.fetch(id)
      end

      def update(id, attrs)
        adapter.update(id, attrs)
      end

      def destroy(id)
        adapter.destroy(id)
      end

      def list(limit: nil)
        limit ||= CsvDrop.config.history_limit
        adapter.list(limit: limit)
      end

      private

      def adapter
        CsvDrop.config.progress_store_adapter
      end
    end
  end
end
