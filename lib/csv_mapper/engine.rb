# frozen_string_literal: true

module CsvMapper
  class Engine < ::Rails::Engine
    isolate_namespace CsvMapper

    config.generators do |g|
      g.test_framework nil
    end
  end
end
