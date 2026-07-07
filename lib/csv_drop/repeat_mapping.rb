# frozen_string_literal: true

module CsvDrop
  class RepeatMapping
    NOT_FOUND_MESSAGE = "Import not found."
    UNAVAILABLE_MESSAGE = "This import cannot be repeated."

    attr_reader :import_id, :model_name, :mapping, :duplicate_key, :duplicate_strategy

    def self.from_import(import_id)
      import = ImportProgressStore.fetch(import_id)
      return nil unless import
      return nil unless repeatable?(import)

      new(
        import_id: import_id,
        model_name: import[:model_name],
        mapping: normalize_mapping(import[:mapping]),
        duplicate_key: import[:duplicate_key],
        duplicate_strategy: import[:duplicate_strategy]
      )
    end

    def self.from_import!(import_id)
      from_import(import_id) || raise(Error, unavailable_message_for(import_id))
    end

    def self.unavailable_message_for(import_id)
      import = ImportProgressStore.fetch(import_id)
      return NOT_FOUND_MESSAGE unless import

      UNAVAILABLE_MESSAGE
    end

    def self.normalize_mapping(mapping)
      (mapping || {}).each_with_object({}) do |(column, attribute), result|
        result[column.to_s] = attribute.to_s
      end
    end

    def self.repeatable?(import)
      import[:status] == "completed" && import[:mapping].present?
    end

    def initialize(import_id:, model_name:, mapping:, duplicate_key: nil, duplicate_strategy: nil)
      @import_id = import_id
      @model_name = model_name
      @mapping = mapping
      @duplicate_key = duplicate_key
      @duplicate_strategy = duplicate_strategy
    end

    def session_attrs
      {
        saved_mapping: mapping,
        duplicate_key: duplicate_key,
        duplicate_strategy: duplicate_strategy,
        repeat_from: import_id
      }
    end

    def mapping_for_header(header, model_columns:)
      saved = mapping[header.to_s]
      return saved if saved.present?

      Mapper.auto_detect_attribute(header, model_columns) || Mapper::SKIP
    end

    private_class_method :repeatable?
  end
end
