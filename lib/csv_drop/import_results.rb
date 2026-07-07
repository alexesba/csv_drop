# frozen_string_literal: true

require "set"

module CsvDrop
  class ImportResults
    STATUS_FILTERS = {
      "failed" => %i[failed].freeze,
      "skipped" => %i[skipped].freeze,
      "imported" => %i[imported valid].freeze,
      "updated" => %i[updated].freeze
    }.freeze

    attr_reader :rows, :current_page, :per_page, :total_count, :status_filter, :query, :unfiltered_count

    def initialize(rows:, page: 1, per_page: CsvDrop.config.results_per_page, status: nil, query: nil)
      @unfiltered_count = rows.size
      @status_filter = normalize_status(status)
      @query = normalize_query(query)
      @rows = apply_filters(rows)
      @total_count = @rows.size
      @per_page = per_page
      @current_page = normalize_page(page)
    end

    def total_pages
      return 1 if @total_count.zero?

      (@total_count.to_f / @per_page).ceil
    end

    def items
      offset = (@current_page - 1) * @per_page
      @rows.slice(offset, @per_page)
    end

    def first_page?
      @current_page <= 1
    end

    def last_page?
      @current_page >= total_pages
    end

    def filtered?
      @status_filter.present? || @query.present?
    end

    # Returns a sequence of page numbers and :gap markers for ellipsis links.
    # Example (page 15 of 50): [1, :gap, 12, 13, 14, 15, 16, 17, 18, :gap, 50]
    def page_sequence(inner_window: 3, outer_window: 1)
      return [] if total_pages <= 1

      pages = Set.new
      pages.merge((1..outer_window).to_a)
      pages.merge((current_page - inner_window..current_page + inner_window).to_a)
      pages.merge(((total_pages - outer_window + 1)..total_pages).to_a)

      sorted = pages.select { |page| page.between?(1, total_pages) }.sort
      sequence = []

      sorted.each_with_index do |page, index|
        sequence << :gap if index.positive? && page > sorted[index - 1] + 1
        sequence << page
      end

      sequence
    end

    def self.matches_query?(row, query)
      normalized = query.downcase

      return true if row.row_number.to_s.include?(normalized)

      row.values.values.any? { |value| value.to_s.downcase.include?(normalized) } ||
        row.messages.any? { |message| message.downcase.include?(normalized) }
    end

    private

    def apply_filters(rows)
      filtered = rows
      filtered = filter_by_status(filtered) if @status_filter
      filtered = filter_by_query(filtered) if @query.present?
      filtered
    end

    def filter_by_status(rows)
      statuses = STATUS_FILTERS.fetch(@status_filter)
      rows.select { |row| statuses.include?(row.status) }
    end

    def filter_by_query(rows)
      rows.select { |row| self.class.matches_query?(row, @query) }
    end

    def normalize_status(status)
      value = status.to_s.presence
      STATUS_FILTERS.key?(value) ? value : nil
    end

    def normalize_query(query)
      query.to_s.strip
    end

    def normalize_page(page)
      page = page.to_i
      page = 1 if page < 1
      [page, total_pages].min
    end
  end
end
