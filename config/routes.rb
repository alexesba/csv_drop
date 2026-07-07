# frozen_string_literal: true

CsvDrop::Engine.routes.draw do
  root to: "imports#new"

  resources :imports, only: %i[index new create show] do
    member do
      get :rejects
      get :repeat
    end

    collection do
      post :preview
      post :dry_run
      get :mapping
    end
  end
end
