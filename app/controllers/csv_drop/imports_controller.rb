# frozen_string_literal: true

module CsvDrop
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
      parsed = Parser.parse(SessionStore.open_csv(session))

      @token = params[:token]
      @model_name = session[:model_name]
      @headers = session[:headers]
      @preview_rows = parsed.preview_rows
      @model_columns = inspector.columns_for_select
      @duplicate_key_options = inspector.duplicate_key_options
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

      inspector = ModelInspector.new(session[:model_name])
      mapping = Mapper.resolve_mapping(
        params.fetch(:mapping, {}).to_unsafe_h,
        session[:headers],
        inspector.columns_for_select
      )

      if CsvDrop.config.async_import?(session[:row_count])
        enqueue_async_import(session, mapping)
      else
        run_sync_import(session, mapping)
      end
    rescue Error => e
      redirect_to new_import_path, alert: e.message
    end

    def dry_run
      session = SessionStore.fetch(params[:token])
      unless session
        redirect_to new_import_path, alert: "Import session expired. Please upload your CSV again."
        return
      end

      inspector = ModelInspector.new(session[:model_name])
      mapping = Mapper.resolve_mapping(
        params.fetch(:mapping, {}).to_unsafe_h,
        session[:headers],
        inspector.columns_for_select
      )

      run_dry_run(session, mapping)
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
        @result = ImportResultPresenter.snapshot_from_progress(@import)
        @model_name = @import[:model_name]
        @import_results = build_import_results(@result.rows)
        @dry_run = @import[:dry_run]
        @session_token = @import[:session_token]
        @mapping = @import[:mapping]
        @duplicate_key = @import[:duplicate_key]
        render :result
      else
        render :processing
      end
    end

    def rejects
      import = ImportProgressStore.fetch(params[:id])
      head :not_found and return unless import
      head :not_found and return unless import[:status] == "completed"

      snapshot = ImportResultPresenter.snapshot_from_progress(import)
      head :no_content and return if snapshot.failure_count.zero?

      csv = RejectsExporter.to_csv(
        rows: snapshot.rows,
        column_headers: snapshot.column_headers
      )

      send_data csv,
        filename: rejects_filename(import),
        type: "text/csv",
        disposition: "attachment"
    end

    private

    def enqueue_async_import(session, mapping)
      import_id = ImportProgressStore.create(
        model_name: session[:model_name],
        total_rows: session[:row_count],
        mapping: mapping,
        **duplicate_options
      )

      ImportJob.perform_later(
        import_id: import_id,
        file_ref: session[:file_ref],
        model_name: session[:model_name],
        mapping: mapping,
        session_token: params[:token],
        **duplicate_options
      )

      redirect_to import_path(import_id)
    end

    def run_sync_import(session, mapping)
      importer = build_importer(session[:model_name], mapping)
      result = importer.import_from_io(SessionStore.open_csv(session))

      SessionStore.destroy(params[:token])

      import_id = ImportProgressStore.create(
        model_name: session[:model_name],
        total_rows: result.total_rows,
        status: "completed",
        **progress_attrs_from_result(result, mapping: mapping)
      )

      redirect_to import_path(import_id)
    end

    def run_dry_run(session, mapping)
      importer = build_importer(session[:model_name], mapping)
      result = importer.dry_run_from_io(SessionStore.open_csv(session))

      import_id = ImportProgressStore.create(
        model_name: session[:model_name],
        total_rows: result.total_rows,
        status: "completed",
        dry_run: true,
        session_token: params[:token],
        **progress_attrs_from_result(result, mapping: mapping)
      )

      redirect_to import_path(import_id)
    end

    def result_content_locals(result)
      {
        result: result,
        model_name: @import[:model_name],
        import_id: @import_id,
        import_results: build_import_results(result.rows),
        dry_run: @import[:dry_run],
        session_token: @import[:session_token],
        mapping: @import[:mapping],
        duplicate_key: @import[:duplicate_key],
        duplicate_strategy: @import[:duplicate_strategy]
      }
    end

    def build_importer(model_name, mapping)
      Importer.new(model_name, mapping, **duplicate_options)
    end

    def duplicate_options
      key = params[:duplicate_key].presence
      return { duplicate_key: nil, duplicate_strategy: nil } if key.blank?

      {
        duplicate_key: key,
        duplicate_strategy: params[:duplicate_strategy]
      }
    end

    def progress_attrs_from_result(result, mapping:)
      {
        mapping: mapping,
        processed_rows: result.total_rows,
        success_count: result.success_count,
        failure_count: result.failure_count,
        skipped_count: result.skipped_count,
        updated_count: result.updated_count,
        rows: ImportResultPresenter.serialize_rows(result),
        **duplicate_options
      }
    end

    def build_import_results(rows)
      ImportResults.new(rows: rows, page: params[:page])
    end

    def render_status_frame
      case @import[:status]
      when "completed"
        result = ImportResultPresenter.snapshot_from_progress(@import)
        render partial: "result_content", locals: result_content_locals(result)
      when "failed"
        render partial: "failed", locals: { import: @import }
      else
        render partial: "progress", locals: { import: @import }
      end
    end

    def upload_io(upload)
      io = upload.respond_to?(:tempfile) ? upload.tempfile : upload
      io.rewind
      io
    end

    def importable_model_options
      CsvDrop.config.resolve_importable_models.map do |model|
        [model.model_name.human, model.name]
      end
    end

    def rejects_filename(import)
      model = import[:model_name].to_s.underscore
      prefix = import[:dry_run] ? "dry-run-rejects" : "import-rejects"
      "#{prefix}-#{model}-#{import[:id].to_s.first(8)}.csv"
    end
  end
end
