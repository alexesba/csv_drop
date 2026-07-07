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

    def self.create_from_upload!(file:, model_name:)
      io = open_upload(file)
      parsed = Parser.parse(io)

      token = SessionStore.create(
        file: io,
        model_name: model_name,
        headers: parsed.headers.map(&:to_s),
        row_count: parsed.row_count
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

      {
        model_name: model_name,
        headers: headers,
        preview_rows: parsed.preview_rows,
        model_columns: inspector.columns_for_select,
        duplicate_key_options: inspector.duplicate_key_options,
        row_count: row_count
      }
    end
  end
end
