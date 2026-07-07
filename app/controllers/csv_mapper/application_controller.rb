# frozen_string_literal: true

module CsvMapper
  class ApplicationController < ActionController::Base
    layout "csv_mapper/application"

    helper CsvMapper::Engine.routes.url_helpers
  end
end
