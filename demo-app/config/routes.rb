Rails.application.routes.draw do
  root to: "showcase#index"
  resources :showcase, only: [:show]
  post "/showcase/submit", to: "showcase#submit", as: :showcase_submit
  post "/showcase/save_project", to: "showcase#save_project", as: :showcase_save_project

  namespace :testing do
    resources :modal
    resources :drawers
    resources :posts
    resource :hide_from_backend, only: [:new, :create]
    resources :smooth_redirects, only: [:new, :create]
    root to: "welcome#index"
  end

  get "/custom-advance-history-url", to: redirect("/")
end
