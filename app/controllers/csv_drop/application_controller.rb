# frozen_string_literal: true

module CsvDrop
  class ApplicationController < ActionController::Base
    layout "csv_drop/application"

    helper CsvDrop::Engine.routes.url_helpers
  end
end
