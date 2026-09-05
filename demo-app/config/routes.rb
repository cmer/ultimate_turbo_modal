Rails.application.routes.draw do
  root to: "showcase#index"
  resources :showcase, only: [:show]
  post "/showcase/submit", to: "showcase#submit", as: :showcase_submit
  post "/showcase/submit_contact", to: "showcase#submit_contact", as: :showcase_submit_contact
  post "/showcase/save_project", to: "showcase#save_project", as: :showcase_save_project
  post "/showcase/save_preferences", to: "showcase#save_preferences", as: :showcase_save_preferences

  namespace :testing do
    resources :modal
    resources :drawers do
      collection do
        get :nested_modal
        post :nested_modal_same_page
        post :nested_modal_other_page
        get :nested_form
        post :submit_nested_form
        get :nested_form_step_two
      end
    end
    resources :posts
    resource :hide_from_backend, only: [:new, :create]
    resources :smooth_redirects, only: [:new, :create]
    resources :races, only: [:index] do
      collection do
        get :morph_preserves_dialog
        get :supersede_close
      end
    end
    get "chat", to: "chats#show", as: :chat
    post "chat/messages", to: "chats#create_message", as: :chat_messages
    post "chat/clear", to: "chats#clear", as: :chat_clear
    root to: "welcome#index"
  end

  get "/custom-advance-history-url", to: redirect("/")
end
