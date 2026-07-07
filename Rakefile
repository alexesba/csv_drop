# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("test/dummy/Gemfile", __dir__)

require "bundler/setup"
require "bundler/gem_tasks"
require "rake/testtask"

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList["test/{csv_mapper,integration}/**/*_test.rb"]
end

task default: :test
