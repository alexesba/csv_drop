# frozen_string_literal: true

require "csv_drop/version"
require "csv_drop/configuration"
require "csv_drop/parser"
require "csv_drop/model_discovery"
require "csv_drop/model_inspector"
require "csv_drop/mapper"
require "csv_drop/result"
require "csv_drop/importer"
require "csv_drop/stores/disk_file_store"
require "csv_drop/stores/active_storage_file_store"
require "csv_drop/stores/file_session_store"
require "csv_drop/stores/redis_session_store"
require "csv_drop/stores/file_progress_store"
require "csv_drop/stores/redis_progress_store"
require "csv_drop/session_store"
require "csv_drop/import_progress_store"
require "csv_drop/import_broadcaster"
require "csv_drop/result_snapshot"

module CsvDrop
  class Error < StandardError; end

  class << self
    def configure
      yield config
      config.reset_store_adapters!
    end

    def config
      @config ||= Configuration.new
    end

    def reset_config!
      @config = nil
    end
  end
end

require "csv_drop/engine" if defined?(Rails)
