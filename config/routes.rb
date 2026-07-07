# frozen_string_literal: true

CsvMapper::Engine.routes.draw do
  root to: "imports#new"

  resources :imports, only: %i[new create show] do
    collection do
      post :preview
      get :mapping
    end
  end
end
