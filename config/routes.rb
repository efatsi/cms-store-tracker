Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  root "campers#index"

  get "/api/products/:id/purchases", to: "api#product_purchases"

  resources :campers, only: [:index, :show] do
    collection do
      get :balances_csv
      get :purchase_history_csv
    end
    resources :cart_items, only: [:create, :update, :destroy]
    resources :purchases, only: [:create, :destroy]
    resources :balance_adjustments, only: [:create, :destroy]
  end

  resources :staff_members, path: 'staff', only: [:index, :show, :create] do
    collection { get :balances_csv }
    resources :cart_items, only: [:create, :update, :destroy], module: :staff
    resources :purchases, only: [:create, :destroy], module: :staff
    resources :balance_adjustments, only: [:create, :destroy], module: :staff
  end

  resources :products, only: [:index, :new, :create, :edit, :update, :destroy]
end
