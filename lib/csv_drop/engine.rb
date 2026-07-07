# frozen_string_literal: true

module CsvDrop
  class Engine < ::Rails::Engine
    isolate_namespace CsvDrop

    config.generators do |g|
      g.test_framework nil
    end
  end
end
