Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "campers#index"

  get "/api/products/:id/purchases", to: "api#product_purchases"

  resources :campers, only: [:index, :show] do
    resources :cart_items, only: [:create, :update, :destroy]
    resources :purchases, only: [:create, :destroy]
    resources :balance_adjustments, only: [:create, :destroy]
  end

  resources :products, only: [:index, :new, :create, :edit, :update, :destroy]
end
