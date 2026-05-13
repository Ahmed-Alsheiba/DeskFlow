Rails.application.routes.draw do
  devise_for :users
  root "ticket#home"
  # Use plural resource name so form_with(model: @ticket) resolves to tickets_path
  resources :tickets, only: [ :new, :create ], controller: "ticket"
end
