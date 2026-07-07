# frozen_string_literal: true

module CsvMapper
  class ModelDiscovery
    class << self
      def all
        ensure_models_loaded!

        base_models
          .reject(&:abstract_class?)
          .select(&:table_exists?)
          .reject { |model| excluded?(model) }
          .sort_by(&:name)
      end

      private

      def ensure_models_loaded!
        return if @models_loaded

        Rails.application.eager_load! unless Rails.application.config.eager_load
        @models_loaded = true
      end

      def base_models
        if defined?(ApplicationRecord)
          ApplicationRecord.descendants
        else
          ActiveRecord::Base.descendants
        end
      end

      def excluded?(model)
        CsvMapper.config.excluded_models_resolved.any? { |excluded| excluded == model }
      end
    end
  end
end
