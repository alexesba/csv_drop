# frozen_string_literal: true

require "securerandom"
require "json"

module CsvDrop
  module Stores
    class RedisProgressStore
      KEY_PREFIX = "csv_drop:import:"

      def initialize(redis:)
        @redis = redis
      end

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
          skipped_count: attrs.fetch(:skipped_count, 0),
          updated_count: attrs.fetch(:updated_count, 0),
          mapping: mapping,
          duplicate_key: attrs.fetch(:duplicate_key, nil),
          duplicate_strategy: attrs.fetch(:duplicate_strategy, nil),
          errors: attrs.fetch(:errors, []),
          rows: attrs.fetch(:rows, []),
          dry_run: attrs.fetch(:dry_run, false),
          session_token: attrs.fetch(:session_token, nil),
          error_message: attrs.fetch(:error_message, nil),
          created_at: Time.now.to_i,
          updated_at: Time.now.to_i
        })
        id
      end

      def fetch(id)
        payload = @redis.get(key(id))
        return nil unless payload

        JSON.parse(payload, symbolize_names: true)
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
        @redis.del(key(id))
      end

      private

      def write(id, data)
        @redis.setex(key(id), progress_ttl.to_i, data.to_json)
      end

      def key(id)
        "#{KEY_PREFIX}#{id}"
      end

      def progress_ttl
        CsvDrop.config.progress_ttl
      end
    end
  end
end
