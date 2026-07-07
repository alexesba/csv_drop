# frozen_string_literal: true

require "fileutils"
require "pathname"

module CsvMapper
  module Stores
    class DiskFileStore
      BACKEND = "disk"

      def store(io, token)
        dir = storage_dir
        FileUtils.mkdir_p(dir)

        path = dir.join("#{token}.csv")
        if io.respond_to?(:path) && File.exist?(io.path)
          FileUtils.cp(io.path, path.to_s)
        else
          io.rewind
          File.write(path.to_s, io.read, mode: "wb")
        end

        { backend: BACKEND, path: path.to_s }
      end

      def open(file_ref)
        path = file_ref[:path] || file_ref["path"]
        raise Error, "Missing disk file path" unless path && File.exist?(path)

        File.open(path)
      end

      def delete(file_ref)
        path = file_ref[:path] || file_ref["path"]
        FileUtils.rm_f(path) if path
      end

      private

      def storage_dir
        Pathname.new(Dir.tmpdir).join("csv_mapper", "files")
      end
    end
  end
end
