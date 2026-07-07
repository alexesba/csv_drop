# frozen_string_literal: true

module CsvDrop
  class ImportHistory
    Entry = Data.define(
      :id, :model_name, :status, :total_rows, :processed_rows,
      :success_count, :failure_count, :skipped_count, :updated_count,
      :dry_run, :created_at, :updated_at, :error_message
    )

    def self.entries(limit: nil)
      limit ||= CsvDrop.config.history_limit
      ImportProgressStore.list(limit: limit).map { |attrs| entry_from(attrs) }
    end

    def self.entry_from(attrs)
      Entry.new(
        id: attrs[:id],
        model_name: attrs[:model_name],
        status: attrs[:status],
        total_rows: attrs[:total_rows] || 0,
        processed_rows: attrs[:processed_rows] || 0,
        success_count: attrs[:success_count] || 0,
        failure_count: attrs[:failure_count] || 0,
        skipped_count: attrs[:skipped_count] || 0,
        updated_count: attrs[:updated_count] || 0,
        dry_run: attrs[:dry_run] == true,
        created_at: attrs[:created_at],
        updated_at: attrs[:updated_at],
        error_message: attrs[:error_message]
      )
    end

    def self.label_for(entry)
      return "Dry run" if entry.dry_run && entry.status == "completed"

      case entry.status
      when "completed" then "Completed"
      when "failed" then "Failed"
      when "running" then "Running"
      when "queued" then "Queued"
      else entry.status.to_s.capitalize
      end
    end

    def self.status_class_for(entry)
      return "status-valid" if entry.dry_run && entry.status == "completed"

      case entry.status
      when "completed" then "status-imported"
      when "failed" then "status-failed"
      else "status-skipped"
      end
    end
  end
end
