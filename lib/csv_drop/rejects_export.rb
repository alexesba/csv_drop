# frozen_string_literal: true

module CsvDrop
  class RejectsExport
    Result = Data.define(:status, :csv, :filename)

    def self.build(import_id)
      new(import_id).build
    end

    def initialize(import_id)
      @import_id = import_id
    end

    def build
      import = ImportProgressStore.fetch(@import_id)
      return Result.new(status: :not_found, csv: nil, filename: nil) unless import
      return Result.new(status: :not_found, csv: nil, filename: nil) unless import[:status] == "completed"

      snapshot = ImportResultPresenter.snapshot_from_progress(import)
      return Result.new(status: :empty, csv: nil, filename: nil) if snapshot.failure_count.zero?

      Result.new(
        status: :ok,
        csv: RejectsExporter.to_csv(
          rows: snapshot.rows,
          column_headers: snapshot.column_headers
        ),
        filename: filename_for(import)
      )
    end

    private

    def filename_for(import)
      model = import[:model_name].to_s.underscore
      prefix = import[:dry_run] ? "dry-run-rejects" : "import-rejects"
      "#{prefix}-#{model}-#{import[:id].to_s.first(8)}.csv"
    end
  end
end
