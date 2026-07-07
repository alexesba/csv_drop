# frozen_string_literal: true

require "csv_mapper/version"
require "csv_mapper/configuration"
require "csv_mapper/parser"
require "csv_mapper/model_discovery"
require "csv_mapper/model_inspector"
require "csv_mapper/mapper"
require "csv_mapper/result"
require "csv_mapper/importer"
require "csv_mapper/stores/disk_file_store"
require "csv_mapper/stores/active_storage_file_store"
require "csv_mapper/stores/file_session_store"
require "csv_mapper/stores/redis_session_store"
require "csv_mapper/stores/file_progress_store"
require "csv_mapper/stores/redis_progress_store"
require "csv_mapper/session_store"
require "csv_mapper/import_progress_store"
require "csv_mapper/import_broadcaster"
require "csv_mapper/result_snapshot"

module CsvMapper
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

require "csv_mapper/engine" if defined?(Rails)
