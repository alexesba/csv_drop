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

      def show_turbo_setup
        return if File.exist?("config/importmap.rb")

        say "\nFor async import UI, also run:", :yellow
        say "  bundle add turbo-rails importmap-rails propshaft"
        say "  rails importmap:install"
        say "  rails turbo:install\n"
      end
    end
  end
end
