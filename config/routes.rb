Rails.application.routes.draw do
  devise_for :users
  root "pages#landing"
  # Use plural resource name so form_with(model: @ticket) resolves to tickets_path
  resources :tickets, only: [ :index, :new, :create, :show, :edit, :update ], controller: "ticket" do
    member do
      patch :claim
      patch :close
    end
    resources :comments, only: [:create], controller: "ticket_comments"
  end

  namespace :admin do
    get "dashboard", to: "dashboard#index"
  end
end
