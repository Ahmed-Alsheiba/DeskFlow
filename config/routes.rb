Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  devise_for :users, controllers: { registrations: "users/registrations" }
  root "pages#landing"
  # One-click read-only demo: signs in the locked-down "preview" account.
  post "preview", to: "preview_sessions#create", as: :preview
  # Leaves the demo (signs out) and forwards to the real sign-up / sign-in page.
  delete "preview", to: "preview_sessions#destroy"
  # Use plural resource name so form_with(model: @ticket) resolves to tickets_path
  resources :tickets, only: [ :index, :new, :create, :show, :edit, :update ], controller: "ticket" do
    member do
      patch :claim
      patch :close
    end
    resources :comments, only: [ :create ], controller: "ticket_comments"
  end

  namespace :admin do
    get "dashboard", to: "dashboard#index"
    resources :users, only: [ :show, :destroy ] do
      member do
        patch :suspend
        patch :reinstate
      end
    end
    resources :terminated_users, only: [ :index, :show ]
  end
end
