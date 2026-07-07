# frozen_string_literal: true

require "csv_mapper/version"
require "csv_mapper/configuration"
require "csv_mapper/parser"
require "csv_mapper/model_discovery"
require "csv_mapper/model_inspector"
require "csv_mapper/mapper"
require "csv_mapper/result"
require "csv_mapper/importer"
require "csv_mapper/session_store"

module CsvMapper
  class Error < StandardError; end

  class << self
    def configure
      yield config
    end

    def config
      @config ||= Configuration.new
    end
  end
end

require "csv_mapper/engine" if defined?(Rails)
