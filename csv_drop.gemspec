# frozen_string_literal: true

require_relative "lib/csv_drop/version"

Gem::Specification.new do |spec|
  spec.name = "csv_drop"
  spec.version = CsvDrop::VERSION
  spec.authors = ["Your Name"]
  spec.email = ["you@example.com"]

  spec.summary = "Import CSV files into Rails models with a visual column-to-field mapping UI"
  spec.description = "A mountable Rails engine that lets users upload CSV files, select a target model, " \
                     "map columns to fields, and import records with validation error reporting."
  spec.homepage = "https://github.com/your-org/csv_drop"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(__dir__) do
    Dir.glob("{app,config,lib,sig}/**/*") + %w[README.md csv_drop.gemspec]
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "csv"
  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "activerecord", ">= 7.0"
  spec.add_dependency "activejob", ">= 7.0"
  spec.add_dependency "turbo-rails", ">= 2.0"

  spec.add_development_dependency "redis", ">= 4.0"
end
