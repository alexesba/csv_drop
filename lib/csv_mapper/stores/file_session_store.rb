# frozen_string_literal: true

require "securerandom"
require "fileutils"
require "json"
require "pathname"

module CsvMapper
  module Stores
    class FileSessionStore
      def initialize(file_store:)
        @file_store = file_store
      end

      def create(file:, model_name:, headers:, row_count:)
        token = SecureRandom.urlsafe_base64(16)
        file_ref = @file_store.store(file, token)

        write_meta(token, {
          model_name: model_name,
          headers: headers,
          row_count: row_count,
          file_ref: file_ref,
          created_at: Time.now.to_i
        })

        token
      end

      def fetch(token)
        cleanup_expired!

        meta_path = meta_path_for(token)
        return nil unless meta_path.exist?

        meta = JSON.parse(File.read(meta_path), symbolize_names: true)
        normalize_session(meta)
      end

      def destroy(token)
        meta_path = meta_path_for(token)
        if meta_path.exist?
          meta = JSON.parse(File.read(meta_path), symbolize_names: true)
          file_ref = meta[:file_ref]
          @file_store.delete(file_ref.transform_keys(&:to_sym)) if file_ref
        end

        FileUtils.rm_f(meta_path)
      end

      private

      def write_meta(token, data)
        FileUtils.mkdir_p(session_dir)
        File.write(meta_path_for(token).to_s, data.to_json)
      end

      def meta_path_for(token)
        session_dir.join("#{token}.json")
      end

      def session_dir
        Pathname.new(Dir.tmpdir).join("csv_mapper", "sessions")
      end

      def session_ttl
        CsvMapper.config.session_ttl
      end

      def cleanup_expired!
        dir = session_dir
        return unless dir.directory?

        cutoff = Time.now.to_i - session_ttl.to_i
        Dir.glob(dir.join("*.json").to_s).each do |path|
          meta = JSON.parse(File.read(path), symbolize_names: true)
          next if meta[:created_at].to_i >= cutoff

          token = File.basename(path, ".json")
          destroy(token)
        end
      end

      def normalize_session(meta)
        file_ref = meta[:file_ref]
        file_ref = file_ref.transform_keys(&:to_sym) if file_ref.is_a?(Hash)

        session = meta.merge(file_ref: file_ref)
        session[:csv_path] = file_ref[:path] if file_ref&.dig(:backend) == DiskFileStore::BACKEND
        session
      end
    end
  end
end
