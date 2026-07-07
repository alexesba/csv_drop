# frozen_string_literal: true

module CsvDrop
  class ImportSession
    EXPIRED_MESSAGE = "Import session expired. Please upload your CSV again."

    attr_reader :token, :data

    def self.fetch!(token)
      data = SessionStore.fetch(token)
      raise Error, EXPIRED_MESSAGE unless data

      new(token: token, data: data)
    end

    def self.from_params!(params)
      fetch!(params[:token])
    end

    def self.create_from_upload!(file:, model_name:, repeat_from: nil)
      io = open_upload(file)
      parsed = Parser.parse(io)
      template = RepeatMapping.from_import(repeat_from) if repeat_from.present?

      if template && model_name != template.model_name
        raise Error, "Target model must be #{template.model_name} when repeating a previous import."
      end

      token = SessionStore.create(
        file: io,
        model_name: model_name,
        headers: parsed.headers.map(&:to_s),
        row_count: parsed.row_count,
        **(template&.session_attrs || {})
      )

      fetch!(token)
    end

    def self.duplicate_options_from(params)
      key = params[:duplicate_key].presence
      return { duplicate_key: nil, duplicate_strategy: nil } if key.blank?

      {
        duplicate_key: key,
        duplicate_strategy: params[:duplicate_strategy]
      }
    end

    def self.open_upload(upload)
      io = if upload.respond_to?(:tempfile)
             upload.tempfile
           elsif upload.is_a?(Pathname)
             File.open(upload)
           else
             upload
           end

      io.rewind if io.respond_to?(:rewind)
      io
    end

    def initialize(token:, data:)
      @token = token
      @data = data
    end

    def model_name
      data[:model_name]
    end

    def row_count
      data[:row_count]
    end

    def headers
      data[:headers]
    end

    def file_ref
      data[:file_ref]
    end

    def async?
      CsvDrop.config.async_import?(row_count)
    end

    def open_csv
      SessionStore.open_csv(data)
    end

    def destroy
      SessionStore.destroy(token)
    end

    def resolve_mapping(params)
      inspector = ModelInspector.new(model_name)
      raw_mapping = params[:mapping] || {}
      raw_mapping = raw_mapping.to_unsafe_h if raw_mapping.respond_to?(:to_unsafe_h)

      Mapper.resolve_mapping(
        raw_mapping,
        headers,
        inspector.columns_for_select
      )
    end

    def mapping_context
      inspector = ModelInspector.new(model_name)
      parsed = Parser.parse(open_csv)
      model_columns = inspector.columns_for_select

      {
        model_name: model_name,
        headers: headers,
        preview_rows: parsed.preview_rows,
        model_columns: model_columns,
        duplicate_key_options: inspector.duplicate_key_options,
        row_count: row_count,
        suggested_mappings: suggested_mappings(model_columns),
        duplicate_key: data[:duplicate_key],
        duplicate_strategy: data[:duplicate_strategy],
        repeat_from: data[:repeat_from]
      }
    end

    def suggested_mappings(model_columns = nil)
      model_columns ||= ModelInspector.new(model_name).columns_for_select
      template = repeat_template

      headers.each_with_object({}) do |header, result|
        result[header] = if template
                           template.mapping_for_header(header, model_columns: model_columns)
                         else
                           Mapper.auto_detect_attribute(header, model_columns) || Mapper::SKIP
                         end
      end
    end

    def repeat_template?
      data[:saved_mapping].present?
    end

    private

    def repeat_template
      return nil unless data[:saved_mapping].present?

      RepeatMapping.new(
        import_id: data[:repeat_from],
        model_name: model_name,
        mapping: RepeatMapping.normalize_mapping(data[:saved_mapping]),
        duplicate_key: data[:duplicate_key],
        duplicate_strategy: data[:duplicate_strategy]
      )
    end
  end
end
