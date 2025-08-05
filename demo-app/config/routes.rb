Rails.application.routes.draw do
  resources :modal
  resources :posts
  resource :hide_from_backend, only: [:new, :create]
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Defines the root path route ("/")
  root to: "welcome#index"
end
