Rails.application.routes.draw do
  devise_for :users
  root "pages#landing"
  # Use plural resource name so form_with(model: @ticket) resolves to tickets_path
  resources :tickets, only: [ :index, :new, :create ], controller: "ticket"
end
