# frozen_string_literal: true

module CsvMapper
  class ImportsController < ApplicationController

    def new
      @importable_models = importable_model_options
    end

    def preview
      unless params[:csv_file].present? && params[:model_name].present?
        redirect_to new_import_path, alert: "Please select a CSV file and a model."
        return
      end

      upload = params[:csv_file]
      io = upload_io(upload)

      parsed = Parser.parse(io)
      inspector = ModelInspector.new(params[:model_name])

      @token = SessionStore.create(
        file: io,
        model_name: params[:model_name],
        headers: parsed.headers.map(&:to_s),
        row_count: parsed.row_count
      )

      @model_name = params[:model_name]
      @headers = parsed.headers.map(&:to_s)
      @preview_rows = parsed.preview_rows
      @model_columns = inspector.columns_for_select
      @row_count = parsed.row_count
    rescue Error, NameError => e
      redirect_to new_import_path, alert: e.message
    end

    def create
      session = SessionStore.fetch(params[:token])
      unless session
        redirect_to new_import_path, alert: "Import session expired. Please upload your CSV again."
        return
      end

      mapping = params.fetch(:mapping, {}).to_unsafe_h
      importer = Importer.new(session[:model_name], mapping)
      result = importer.import_from_file(session[:csv_path])

      SessionStore.destroy(params[:token])

      @result = result
      @model_name = session[:model_name]
      render :result
    rescue Error => e
      redirect_to new_import_path, alert: e.message
    end

    private

    def upload_io(upload)
      io = upload.respond_to?(:tempfile) ? upload.tempfile : upload
      io.rewind
      io
    end

    def importable_model_options
      CsvMapper.config.resolve_importable_models.map do |model|
        [model.model_name.human, model.name]
      end
    end
  end
end
