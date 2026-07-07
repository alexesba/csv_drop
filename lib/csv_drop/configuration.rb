# frozen_string_literal: true

module CsvDrop
  class Configuration
    attr_accessor :importable_models, :excluded_models, :excluded_columns, :max_rows, :batch_size,
                  :mount_path, :async_imports, :async_row_threshold, :progress_broadcast_every,
                  :results_per_page, :history_limit, :duplicate_keys, :default_duplicate_strategy, :session_store,
                  :progress_store, :file_store, :redis, :session_ttl, :progress_ttl

    def initialize
      @importable_models = nil # nil = auto-discover all ActiveRecord models
      @excluded_models = []
      @excluded_columns = %i[id created_at updated_at]
      @max_rows = nil
      @batch_size = 100
      @mount_path = "/csv_drop"
      @async_imports = true
      @async_row_threshold = 50
      @progress_broadcast_every = 10
      @results_per_page = 50
      @history_limit = 50
      @duplicate_keys = {}
      @default_duplicate_strategy = :skip
      @session_store = :auto
      @progress_store = :auto
      @file_store = :auto
      @redis = nil
      @session_ttl = 1.hour
      @progress_ttl = 24.hours
    end

    def async_import?(row_count)
      async_imports && row_count >= async_row_threshold
    end

    def duplicate_keys_for(model)
      name = model.is_a?(Class) ? model.name : model.to_s
      keys = duplicate_keys[name] || duplicate_keys[name.to_sym]
      Array(keys).map(&:to_s)
    end

    def resolve_importable_models
      models = explicit_importable_models || ModelDiscovery.all
      models - excluded_models_resolved
    end

    def explicit_importable_models
      return nil if importable_models.nil?

      models = importable_models
      models = models.call if models.respond_to?(:call)
      models.map { |m| m.is_a?(String) ? m.constantize : m }
    end

    def excluded_models_resolved
      models = excluded_models
      models = models.call if models.respond_to?(:call)
      Array(models).map { |m| m.is_a?(String) ? m.constantize : m }
    end

    def file_store_adapter
      @file_store_adapter ||= build_file_store_adapter
    end

    def session_store_adapter
      @session_store_adapter ||= build_session_store_adapter
    end

    def progress_store_adapter
      @progress_store_adapter ||= build_progress_store_adapter
    end

    def redis_client
      @redis_client ||= resolve_redis_client
    end

    def reset_store_adapters!
      @file_store_adapter = nil
      @session_store_adapter = nil
      @progress_store_adapter = nil
      @redis_client = nil
    end

    private

    def build_file_store_adapter
      case resolved_file_store
      when :disk
        Stores::DiskFileStore.new
      when :active_storage
        Stores::ActiveStorageFileStore.new
      else
        resolved_file_store
      end
    end

    def build_session_store_adapter
      case resolved_session_store
      when :file
        Stores::FileSessionStore.new(file_store: file_store_adapter)
      when :redis
        Stores::RedisSessionStore.new(file_store: file_store_adapter, redis: redis_client)
      else
        resolved_session_store
      end
    end

    def build_progress_store_adapter
      case resolved_progress_store
      when :file
        Stores::FileProgressStore.new
      when :redis
        Stores::RedisProgressStore.new(redis: redis_client)
      else
        resolved_progress_store
      end
    end

    def resolved_session_store
      resolve_store_setting(session_store)
    end

    def resolved_progress_store
      resolve_store_setting(progress_store)
    end

    def resolved_file_store
      case file_store
      when :auto
        active_storage_available? ? :active_storage : :disk
      when Symbol
        file_store
      else
        file_store
      end
    end

    def resolve_store_setting(setting)
      return setting unless setting == :auto

      redis_available? ? :redis : :file
    end

    def redis_available?
      return true if redis

      defined?(Rails) && ENV["REDIS_URL"].present?
    end

    def resolve_redis_client
      client = redis
      client = client.call if client.respond_to?(:call)
      return client if client

      require_redis!
      Redis.new(url: ENV.fetch("REDIS_URL"))
    end

    def require_redis!
      require "redis"
    rescue LoadError
      raise Error, "The redis gem is required for Redis store backends. Add `gem \"redis\"` to your Gemfile."
    end

    def active_storage_available?
      return false unless defined?(ActiveStorage::Blob)

      ActiveStorage::Blob.table_exists?
    rescue StandardError
      false
    end
  end
end
