# frozen_string_literal: true

module CsvMapper
  class Configuration
    attr_accessor :importable_models, :excluded_models, :excluded_columns, :max_rows, :batch_size, :mount_path

    def initialize
      @importable_models = nil # nil = auto-discover all ActiveRecord models
      @excluded_models = []
      @excluded_columns = %i[id created_at updated_at]
      @max_rows = nil
      @batch_size = 100
      @mount_path = "/csv_import"
    end

    def resolve_importable_models
      models = explicit_importable_models || ModelDiscovery.all
      models - excluded_models_resolved
    end

    def explicit_importable_models
      return nil if importable_models.nil?

      models = importable_models
      models = models.call if models.respond_to?(:call)
      models.map { |m| m.is_a?(String) ? m.constantize : m }
    end

    def excluded_models_resolved
      models = excluded_models
      models = models.call if models.respond_to?(:call)
      Array(models).map { |m| m.is_a?(String) ? m.constantize : m }
    end
  end
end
