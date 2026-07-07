Rails.application.routes.draw do
  mount CsvDrop::Engine, at: "/csv_drop"

  get "up" => "rails/health#show", as: :rails_health_check
end
