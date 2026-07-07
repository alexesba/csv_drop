# frozen_string_literal: true

module CsvDrop
  class ImportCoordinator
    def initialize(session:, mapping:, duplicate_options:)
      @session = session
      @mapping = mapping
      @duplicate_options = duplicate_options
    end

    def start_sync!
      result = importer.import_from_io(@session.open_csv)
      @session.destroy
      persist_completed_result(result)
    end

    def start_dry_run!
      result = importer.dry_run_from_io(@session.open_csv)
      persist_completed_result(result, dry_run: true, session_token: @session.token)
    end

    def start_async!
      import_id = ImportProgressStore.create(
        model_name: @session.model_name,
        total_rows: @session.row_count,
        mapping: @mapping,
        **@duplicate_options
      )

      ImportJob.perform_later(
        import_id: import_id,
        file_ref: @session.file_ref,
        model_name: @session.model_name,
        mapping: @mapping,
        session_token: @session.token,
        **@duplicate_options
      )

      import_id
    end

    private

    def importer
      Importer.new(@session.model_name, @mapping, **@duplicate_options)
    end

    def persist_completed_result(result, dry_run: false, session_token: nil)
      ImportProgressStore.create(
        model_name: @session.model_name,
        total_rows: result.total_rows,
        status: "completed",
        dry_run: dry_run,
        session_token: session_token,
        **progress_attrs(result)
      )
    end

    def progress_attrs(result)
      {
        mapping: @mapping,
        processed_rows: result.total_rows,
        success_count: result.success_count,
        failure_count: result.failure_count,
        skipped_count: result.skipped_count,
        updated_count: result.updated_count,
        rows: ImportResultPresenter.serialize_rows(result),
        **@duplicate_options
      }
    end
  end
end
