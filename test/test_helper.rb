# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("dummy/Gemfile", __dir__)
ENV["RAILS_ENV"] ||= "test"

require "bundler/setup"

dummy_root = File.expand_path("dummy", __dir__)
require File.join(dummy_root, "config/environment")

require "rails/test_help"
require "csv_mapper"

CsvMapper.configure do |config|
  config.session_store = :file
  config.progress_store = :file
  config.file_store = :disk
end

module ActiveSupport
  class TestCase
    include ActionDispatch::TestProcess

    parallelize(workers: 1)

    fixtures :all if respond_to?(:fixtures)
  end
end
