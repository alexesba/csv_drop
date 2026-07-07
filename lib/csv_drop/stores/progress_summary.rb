# frozen_string_literal: true

module CsvDrop
  module Stores
    module ProgressSummary
      SUMMARY_KEYS = %i[
        id model_name status total_rows processed_rows
        success_count failure_count skipped_count updated_count
        dry_run created_at updated_at error_message
      ].freeze

      module_function

      def summarize(progress)
        progress.slice(*SUMMARY_KEYS)
      end
    end
  end
end
