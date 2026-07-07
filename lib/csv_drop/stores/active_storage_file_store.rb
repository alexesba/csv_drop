# frozen_string_literal: true

module CsvDrop
  module Stores
    class ActiveStorageFileStore
      BACKEND = "active_storage"

      def store(io, token)
        ensure_active_storage!

        io.rewind if io.respond_to?(:rewind)
        blob = ActiveStorage::Blob.create_and_upload!(
          io: io,
          filename: "import-#{token}.csv",
          content_type: "text/csv"
        )

        { backend: BACKEND, signed_id: blob.signed_id }
      end

      def open(file_ref)
        ensure_active_storage!

        signed_id = file_ref[:signed_id] || file_ref["signed_id"]
        blob = ActiveStorage::Blob.find_signed!(signed_id)
        blob.download
      end

      def delete(file_ref)
        ensure_active_storage!

        signed_id = file_ref[:signed_id] || file_ref["signed_id"]
        blob = ActiveStorage::Blob.find_signed(signed_id)
        blob&.purge
      end

      private

      def ensure_active_storage!
        return if defined?(ActiveStorage::Blob)

        raise Error, "Active Storage is not available. Configure config.file_store = :disk or add Active Storage to your app."
      end
    end
  end
end
