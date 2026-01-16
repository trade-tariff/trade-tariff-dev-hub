Rails.application.routes.draw do
  get "healthcheckz" => "rails/health#show", as: :rails_health_check

  root "homepage#index"

  get '/auth/redirect', to: 'sessions#handle_redirect'
  get '/auth/invalid', to: 'sessions#invalid'
  get '/auth/logout', to: 'sessions#destroy', as: :logout

  if TradeTariffDevHub.dev_bypass_auth_enabled?
    get '/dev/login', to: 'dev_auth#new', as: :dev_login
    post '/dev/login', to: 'dev_auth#create'
    delete '/dev/logout', to: 'dev_auth#destroy', as: :dev_logout
  end

  resources :organisations, only: %i[index show edit update]
  resources :users, only: %i[destroy]
  get 'users/:id/remove', to: 'users#remove', as: :remove_user

  resources :invitations, only: %i[new create edit update] do
    member do
      get :resend, to: 'invitations#resend', as: :resend
      get :delete, to: 'invitations#update', as: :delete
      delete :delete
    end
  end

  if false
    resources :role_requests, only: %i[new create]
  end

  resources :api_keys, only: %i[index new create] do
    member do
      get :revoke, to: 'api_keys#update', as: :revoke
      patch :revoke

      if TradeTariffDevHub.deletion_enabled?
        get :delete, to: 'api_keys#update', as: :delete
        delete :delete
      end
    end
  end

  # resources :trade_tariff_keys, only: %i[index new create] do
  #   member do
  #     get :revoke, to: 'trade_tariff_keys#update', as: :revoke
  #     patch :revoke
  #     get :delete, to: 'trade_tariff_keys#update', as: :delete
  #     delete :delete
  #   end
  # end

  namespace :user_verification do
    resources :steps, only: %i[show update index] do
      collection do
        get :completed
        get :rejected
      end
    end
  end

  namespace :admin do
    resources :organisations, only: [:index, :show], path: 'organisations' do
      post :roles, to: 'organisation_roles#create'
      delete :roles, to: 'organisation_roles#destroy'
    end

    resources :role_requests, only: [:index] do
      member do
        post :approve
      end
    end
  end

  get :privacy, to: "pages#privacy"
  get :cookies, to: "pages#cookies"

  match "/400", to: "errors#bad_request", via: :all
  match "/404", to: "errors#not_found", via: :all, as: :not_found
  match "/405", to: "errors#method_not_allowed", via: :all
  match "/406", to: "errors#not_acceptable", via: :all
  match "/422", to: "errors#unprocessable_entity", via: :all
  match "/429", to: "errors#too_many_requests", via: :all
  match "/500", to: "errors#internal_server_error", via: :all
  match "/501", to: "errors#not_implemented", via: :all
  match "/503", to: "errors#maintenance", via: :all
  match "*path", to: "errors#not_found", via: :all
end
