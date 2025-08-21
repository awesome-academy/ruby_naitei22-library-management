Rails.application.routes.draw do
  get "/auth/:provider/callback", to: "sessions#omniauth"
  post "/auth/:provider/callback", to: "sessions#omniauth"
  get "/auth/:provider", to: redirect { |params, request| "/auth/#{params[:provider]}" }, as: :auth_provider

  scope "(:locale)", locale: /en|vi/ do
    namespace :admin do
      resources :users, only: [:index, :show] do
        member do
          patch :toggle_status
        end
      end
      resources :borrow_requests, only: [:index,:show] do
        member do
          get :edit_status
          patch :change_status
        end
      end
    end

    root "static_pages#home"

    get "/home",    to: "static_pages#home",    as: :home
    get "/help",    to: "static_pages#help",    as: :help
    get "/contact", to: "static_pages#contact", as: :contact

    get "signup",   to: "users#new",            as: :signup
    post "signup",  to: "users#create"

    get "login",    to: "sessions#new",         as: :login
    post "login",   to: "sessions#create"
    delete "logout",to: "sessions#destroy",     as: :logout

    get "/setup_password", to: "users#setup_password"
    patch "/setup_password", to: "users#update_password"

    get "search", to: "books#search", as: :search_books

    resources :password_resets, only: [:new, :create, :edit, :update]
    resources :users, only: [:show, :new, :create, :edit, :update] do
      member do
        get :favorites
        get :follows
        get :setup_password
        patch :update_password
      end
      resources :password_resets, only: [:new, :create, :edit, :update]
    end
    resources :account_activations, only: :edit
    resources :password_resets, only: %i(new create edit update)
    namespace :admin do
      resources :books
      resources :authors
      resources :publishers
      resources :categories
      resource :report, only: :show
    end
    resources :books, only: [:show] do
      member do
        post :borrow
        post :add_to_favorite
        delete :remove_from_favorite
        post :write_a_review
        delete :destroy_review
      end
    end
    resources :authors, only: [:show] do
      member do
        post :add_to_favorite
        delete :remove_from_favorite
      end
    end

    resources :authors, only: [:show] do
      member do
        post :add_to_favorite
        delete :remove_from_favorite
      end
    end

    resources :borrow_request, only: [:index] do
      collection do
        delete :remove_from_borrow_cart
        patch :update_borrow_cart
        post :checkout
      end
    end
    resources :borrow_list, only: [:index, :show] do
      member do
        patch :cancel, to: "borrow_list#cancel", as: :cancel
        get :edit_request, to: "borrow_list#edit_request", as: :edit_request
        patch :update_request, to: "borrow_list#update_request", as: :update_request
      end
    end
  end
end
