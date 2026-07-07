# frozen_string_literal: true

require "set"

module CsvDrop
  class ImportResults
    attr_reader :rows, :current_page, :per_page, :total_count

    def initialize(rows:, page: 1, per_page: CsvDrop.config.results_per_page)
      @rows = rows
      @total_count = rows.size
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

    private

    def normalize_page(page)
      page = page.to_i
      page = 1 if page < 1
      [page, total_pages].min
    end
  end
end
