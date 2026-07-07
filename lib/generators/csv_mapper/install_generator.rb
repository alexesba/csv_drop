# frozen_string_literal: true

require "generators/rails"

module CsvMapper
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path("templates", __dir__)

      desc "Install CsvMapper: mounts the engine (no configuration required)"

      def create_initializer
        template "csv_mapper.rb", "config/initializers/csv_mapper.rb"
      end

      def mount_engine
        route 'mount CsvMapper::Engine, at: "/csv_import"'
      end
    end
  end
end
