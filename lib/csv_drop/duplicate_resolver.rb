# frozen_string_literal: true

module CsvDrop
  class DuplicateResolver
    STRATEGIES = %i[skip update fail].freeze

    def self.normalize_strategy(value)
      strategy = value.to_s.presence&.to_sym || :skip
      return strategy if STRATEGIES.include?(strategy)

      raise Error, "Invalid duplicate strategy: #{value}"
    end

    def initialize(model_class:, key:)
      @model_class = model_class.is_a?(String) ? model_class.constantize : model_class
      @key = key.to_s
    end

    def enabled?
      @key.present?
    end

    def key
      @key
    end

    def find_existing(attributes)
      lookup_value = attributes[@key]
      return nil if lookup_value.nil? || lookup_value.to_s.strip.empty?

      @model_class.find_by(@key => lookup_value)
    end

    def duplicate_message
      "Duplicate record already exists (#{@key})"
    end
  end
end
