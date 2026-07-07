# frozen_string_literal: true

require_relative "lib/csv_drop/version"

Gem::Specification.new do |spec|
  spec.name = "csv_drop"
  spec.version = CsvDrop::VERSION
  spec.authors = ["Alejandro Espinoza"]
  spec.email = ["alexesba@gmail.com"]

  spec.summary = "Zero-config CSV import for Rails with column mapping UI"
  spec.description = <<~DESC.delete("\n")
    CsvDrop is a mountable Rails engine for importing CSV files into any ActiveRecord model.
    Upload a file, map columns to fields, preview or dry-run, then import with per-row validation,
    async progress, duplicate handling, paginated results, and rejects export.
  DESC
  spec.homepage = "https://github.com/alexesba/csv_drop"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["rubygems_mfa_required"] = "true"

  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |path|
      path.start_with?("test/", "vendor/", ".ruby-lsp/")
    end
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "csv"
  spec.add_dependency "rails", ">= 7.0"
  spec.add_dependency "activerecord", ">= 7.0"
  spec.add_dependency "activejob", ">= 7.0"
  spec.add_dependency "turbo-rails", ">= 2.0"

  spec.add_development_dependency "minitest", ">= 5.0"
  spec.add_development_dependency "rake", ">= 13.0"
  spec.add_development_dependency "redis", ">= 4.0"
end
