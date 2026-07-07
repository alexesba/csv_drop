# frozen_string_literal: true

CsvDrop::Engine.routes.draw do
  root to: "imports#new"

  resources :imports, only: %i[new create show] do
    collection do
      post :preview
      post :dry_run
      get :mapping
    end
  end
end
