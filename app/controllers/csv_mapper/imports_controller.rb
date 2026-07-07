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

      redirect_to mapping_imports_path(token: @token)
    rescue Error, NameError => e
      redirect_to new_import_path, alert: e.message
    end

    def mapping
      session = SessionStore.fetch(params[:token])
      unless session
        redirect_to new_import_path, alert: "Import session expired. Please upload your CSV again."
        return
      end

      inspector = ModelInspector.new(session[:model_name])
      parsed = Parser.parse(File.open(session[:csv_path]))

      @token = params[:token]
      @model_name = session[:model_name]
      @headers = session[:headers]
      @preview_rows = parsed.preview_rows
      @model_columns = inspector.columns_for_select
      @row_count = session[:row_count]
      render :preview
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

      if CsvMapper.config.async_import?(session[:row_count])
        enqueue_async_import(session, mapping)
      else
        run_sync_import(session, mapping)
      end
    rescue Error => e
      redirect_to new_import_path, alert: e.message
    end

    def show
      @import = ImportProgressStore.fetch(params[:id])
      head :not_found and return unless @import

      @import_id = params[:id]

      if turbo_frame_request?
        render_status_frame
        return
      end

      case @import[:status]
      when "completed"
        @result = result_from_progress(@import)
        @model_name = @import[:model_name]
        render :result
      else
        render :processing
      end
    end

    private

    def enqueue_async_import(session, mapping)
      import_id = ImportProgressStore.create(
        model_name: session[:model_name],
        total_rows: session[:row_count],
        mapping: mapping
      )

      ImportJob.perform_later(
        import_id: import_id,
        csv_path: session[:csv_path],
        model_name: session[:model_name],
        mapping: mapping,
        session_token: params[:token]
      )

      redirect_to import_path(import_id)
    end

    def run_sync_import(session, mapping)
      importer = Importer.new(session[:model_name], mapping)
      result = importer.import_from_file(session[:csv_path])

      SessionStore.destroy(params[:token])

      import_id = ImportProgressStore.create(
        model_name: session[:model_name],
        total_rows: result.total_rows,
        mapping: mapping,
        status: "completed",
        processed_rows: result.total_rows,
        success_count: result.success_count,
        failure_count: result.failure_count,
        errors: serialize_errors(result)
      )

      redirect_to import_path(import_id)
    end

    def serialize_errors(result)
      result.errors.map do |error|
        {
          row_number: error.row_number,
          attributes: error.attributes,
          messages: error.messages
        }
      end
    end

    def render_status_frame
      case @import[:status]
      when "completed"
        render partial: "result_content", locals: {
          result: result_from_progress(@import),
          model_name: @import[:model_name]
        }
      when "failed"
        render partial: "failed", locals: { import: @import }
      else
        render partial: "progress", locals: { import: @import }
      end
    end

    def result_from_progress(import)
      errors = import.fetch(:errors, []).map do |error|
        Result::RowError.new(
          row_number: error[:row_number] || error["row_number"],
          attributes: error[:attributes] || error["attributes"],
          messages: error[:messages] || error["messages"]
        )
      end

      ResultSnapshot.new(
        total_rows: import[:total_rows],
        success_count: import[:success_count],
        failure_count: import[:failure_count],
        errors: errors
      )
    end

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
