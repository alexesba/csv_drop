# frozen_string_literal: true

module CsvDrop
  class ImportsController < ApplicationController

    def new
      @importable_models = importable_model_options
    end

    def index
      @imports = ImportHistory.entries
    end

    def repeat
      @repeat = RepeatMapping.from_import(params[:id])
      head :not_found and return unless @repeat
    end

    def preview
      repeat_from = params[:repeat_from].presence

      unless params[:csv_file].present?
        redirect_with_upload_alert(repeat_from)
        return
      end

      model_name = resolve_preview_model_name(repeat_from)
      unless model_name.present?
        redirect_to new_import_path, alert: "Please select a model."
        return
      end

      @token = ImportSession.create_from_upload!(
        file: params[:csv_file],
        model_name: model_name,
        repeat_from: repeat_from
      ).token

      redirect_to mapping_imports_path(token: @token)
    rescue Error, NameError => e
      redirect_with_upload_alert(repeat_from, e.message)
    end

    def mapping
      session = ImportSession.fetch!(params[:token])
      assign_mapping_variables(session)

      render :preview
    rescue Error, NameError => e
      redirect_to new_import_path, alert: e.message
    end

    def create
      run_import(dry_run: false)
    end

    def dry_run
      run_import(dry_run: true)
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
        assign_result_variables
        render :result
      else
        render :processing
      end
    end

    def rejects
      export = RejectsExport.build(params[:id])

      case export.status
      when :not_found
        head :not_found
      when :empty
        head :no_content
      else
        send_data export.csv,
          filename: export.filename,
          type: "text/csv",
          disposition: "attachment"
      end
    end

    private

    def run_import(dry_run:)
      session = ImportSession.from_params!(params)
      mapping = session.resolve_mapping(params)
      duplicate_options = ImportSession.duplicate_options_from(params)
      coordinator = ImportCoordinator.new(
        session: session,
        mapping: mapping,
        duplicate_options: duplicate_options
      )

      import_id = if dry_run
                    coordinator.start_dry_run!
                  elsif session.async?
                    coordinator.start_async!
                  else
                    coordinator.start_sync!
                  end

      redirect_to import_path(import_id)
    rescue Error => e
      redirect_to new_import_path, alert: e.message
    end

    def assign_mapping_variables(session)
      context = session.mapping_context

      @token = session.token
      @model_name = context[:model_name]
      @headers = context[:headers]
      @preview_rows = context[:preview_rows]
      @model_columns = context[:model_columns]
      @duplicate_key_options = context[:duplicate_key_options]
      @row_count = context[:row_count]
      @suggested_mappings = context[:suggested_mappings]
      @duplicate_key = context[:duplicate_key]
      @duplicate_strategy = context[:duplicate_strategy]
      @repeat_from = context[:repeat_from]
    end

    def resolve_preview_model_name(repeat_from)
      return params[:model_name].presence unless repeat_from.present?

      RepeatMapping.from_import!(repeat_from).model_name
    end

    def redirect_with_upload_alert(repeat_from, message = "Please select a CSV file and a model.")
      if repeat_from.present?
        redirect_to repeat_import_path(repeat_from), alert: message
      else
        redirect_to new_import_path, alert: message
      end
    end

    def assign_result_variables
      @result = ImportResultPresenter.snapshot_from_progress(@import)
      @model_name = @import[:model_name]
      @import_results = build_import_results(@result.rows)
      @dry_run = @import[:dry_run]
      @session_token = @import[:session_token]
      @mapping = @import[:mapping]
      @duplicate_key = @import[:duplicate_key]
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

    def build_import_results(rows)
      ImportResults.new(
        rows: rows,
        page: params[:page],
        status: params[:status],
        query: params[:q]
      )
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

    def importable_model_options
      CsvDrop.config.resolve_importable_models.map do |model|
        [model.model_name.human, model.name]
      end
    end
  end
end
