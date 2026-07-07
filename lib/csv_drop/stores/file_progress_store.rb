# frozen_string_literal: true

require "securerandom"
require "fileutils"
require "json"
require "pathname"

module CsvDrop
  module Stores
    class FileProgressStore
      STATUSES = %w[queued running completed failed].freeze

      def create(model_name:, total_rows:, mapping:, **attrs)
        id = SecureRandom.urlsafe_base64(16)
        write(id, {
          id: id,
          status: attrs.fetch(:status, "queued"),
          model_name: model_name,
          total_rows: total_rows,
          processed_rows: attrs.fetch(:processed_rows, 0),
          success_count: attrs.fetch(:success_count, 0),
          failure_count: attrs.fetch(:failure_count, 0),
          mapping: mapping,
          errors: attrs.fetch(:errors, []),
          rows: attrs.fetch(:rows, []),
          failed_rows: attrs.fetch(:failed_rows, []),
          dry_run: attrs.fetch(:dry_run, false),
          session_token: attrs.fetch(:session_token, nil),
          error_message: attrs.fetch(:error_message, nil),
          created_at: Time.now.to_i,
          updated_at: Time.now.to_i
        })
        id
      end

      def fetch(id)
        path = progress_path(id)
        return nil unless path.exist?

        JSON.parse(File.read(path), symbolize_names: true)
      end

      def update(id, attrs)
        progress = fetch(id)
        return nil unless progress

        progress.merge!(attrs)
        progress[:updated_at] = Time.now.to_i
        write(id, progress)
        progress
      end

      def destroy(id)
        FileUtils.rm_f(progress_path(id))
      end

      private

      def progress_dir
        Pathname.new(Dir.tmpdir).join("csv_drop", "imports")
      end

      def progress_path(id)
        progress_dir.join("#{id}.json")
      end

      def write(id, data)
        FileUtils.mkdir_p(progress_dir)
        File.write(progress_path(id).to_s, data.to_json)
      end
    end
  end
end
