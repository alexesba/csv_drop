# frozen_string_literal: true

require "stringio"

module CsvDrop
  class SessionStore
    class << self
      def create(file:, model_name:, headers:, row_count:)
        adapter.create(
          file: file,
          model_name: model_name,
          headers: headers,
          row_count: row_count
        )
      end

      def fetch(token)
        adapter.fetch(token)
      end

      def destroy(token)
        adapter.destroy(token)
      end

      def open_csv(session)
        file_ref = session[:file_ref]
        raise Error, "Import session is missing file data" unless file_ref

        io = CsvDrop.config.file_store_adapter.open(file_ref)
        io.respond_to?(:rewind) ? io : StringIO.new(io)
      end

      private

      def adapter
        CsvDrop.config.session_store_adapter
      end
    end
  end
end
