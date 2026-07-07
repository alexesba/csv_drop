Rails.application.routes.draw do
  mount CsvMapper::Engine, at: "/csv_import"

  get "up" => "rails/health#show", as: :rails_health_check
end
