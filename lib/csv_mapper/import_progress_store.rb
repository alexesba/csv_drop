# frozen_string_literal: true

module CsvMapper
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

      private

      def adapter
        CsvMapper.config.progress_store_adapter
      end
    end
  end
end
