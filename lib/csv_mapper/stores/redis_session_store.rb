# frozen_string_literal: true

require "securerandom"
require "json"

module CsvMapper
  module Stores
    class RedisSessionStore
      KEY_PREFIX = "csv_mapper:session:"

      def initialize(file_store:, redis:)
        @file_store = file_store
        @redis = redis
      end

      def create(file:, model_name:, headers:, row_count:)
        token = SecureRandom.urlsafe_base64(16)
        file_ref = @file_store.store(file, token)

        write(token, {
          model_name: model_name,
          headers: headers,
          row_count: row_count,
          file_ref: file_ref,
          created_at: Time.now.to_i
        })

        token
      end

      def fetch(token)
        payload = @redis.get(key(token))
        return nil unless payload

        normalize_session(JSON.parse(payload, symbolize_names: true))
      end

      def destroy(token)
        session = fetch(token)
        @file_store.delete(session[:file_ref]) if session&.dig(:file_ref)
        @redis.del(key(token))
      end

      private

      def write(token, data)
        @redis.setex(key(token), session_ttl.to_i, data.to_json)
      end

      def key(token)
        "#{KEY_PREFIX}#{token}"
      end

      def session_ttl
        CsvMapper.config.session_ttl
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
