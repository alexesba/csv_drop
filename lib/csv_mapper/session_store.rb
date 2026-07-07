# frozen_string_literal: true

require "securerandom"
require "fileutils"
require "json"
require "pathname"

module CsvMapper
  class SessionStore
    SESSION_TTL = 1.hour

    class << self
      def create(file:, model_name:, headers:, row_count:)
        token = SecureRandom.urlsafe_base64(16)
        dir = session_dir
        FileUtils.mkdir_p(dir)

        csv_path = dir.join("#{token}.csv")
        FileUtils.cp(file.path, csv_path.to_s)

        meta_path = dir.join("#{token}.json")
        File.write(meta_path.to_s, {
          model_name: model_name,
          headers: headers,
          row_count: row_count,
          created_at: Time.now.to_i
        }.to_json)

        token
      end

      def fetch(token)
        cleanup_expired!

        csv_path = session_dir.join("#{token}.csv")
        meta_path = session_dir.join("#{token}.json")

        return nil unless csv_path.exist? && meta_path.exist?

        meta = JSON.parse(File.read(meta_path), symbolize_names: true)
        { csv_path: csv_path.to_s, **meta }
      end

      def destroy(token)
        FileUtils.rm_f(session_dir.join("#{token}.csv"))
        FileUtils.rm_f(session_dir.join("#{token}.json"))
      end

      private

      def session_dir
        Pathname.new(Dir.tmpdir).join("csv_mapper", "sessions")
      end

      def cleanup_expired!
        dir = session_dir
        return unless dir.directory?

        cutoff = Time.now.to_i - SESSION_TTL.to_i
        Dir.glob(dir.join("*.json").to_s).each do |meta_path|
          meta = JSON.parse(File.read(meta_path))
          next if meta["created_at"].to_i >= cutoff

          token = File.basename(meta_path, ".json")
          FileUtils.rm_f(meta_path)
          FileUtils.rm_f(dir.join("#{token}.csv"))
        end
      end
    end
  end
end
