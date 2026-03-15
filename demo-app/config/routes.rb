Rails.application.routes.draw do
  root to: "showcase#index"
  resources :showcase, only: [:show]
  post "/showcase/submit", to: "showcase#submit", as: :showcase_submit

  namespace :testing do
    resources :modal
    resources :drawers
    resources :posts
    resource :hide_from_backend, only: [:new, :create]
    root to: "welcome#index"
  end

  get "/custom-advance-history-url", to: redirect("/")
end
