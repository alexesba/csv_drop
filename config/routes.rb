# frozen_string_literal: true

CsvMapper::Engine.routes.draw do
  root to: "imports#new"

  resources :imports, only: %i[new create] do
    collection do
      post :preview
    end
  end
end
