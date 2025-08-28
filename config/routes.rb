Rails.application.routes.draw do
  devise_for :users, only: [:sessions, :unlocks, :registrations, :passwords,
:omniauth_callbacks], controllers: {
    sessions: "sessions",
    registrations: "users/registrations",
    omniauth_callbacks: "users/omniauth_callbacks",
    passwords: "password_resets"
  }

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

    get "search", to: "books#search", as: :search_books

    resources :users, only: [:show, :edit, :update] do
      member do
        get :favorites
        get :follows
        get :setup_password
        patch :update_password
      end
    end

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
      end
    end
  end
end
