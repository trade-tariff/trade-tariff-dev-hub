Rails.application.routes.draw do
  get "healthcheckz" => "rails/health#show", as: :rails_health_check

  root "homepage#index"

  get '/auth/redirect', to: 'sessions#handle_redirect'
  get '/auth/failure', to: 'sessions#failure'
  get '/auth/logout', to: 'sessions#destroy', as: :logout
  get '/auth/profile-redirect', to: redirect(path: '/dashboard'), as: :profile_redirect
  get '/auth/group-redirect', to: redirect(path: '/dashboard'), as: :group_redirect

  get "dashboard", to: "api_keys#index", as: :api_keys
  get "dashboard/new", to: "api_keys#new", as: :api_keys_new
  post "dashboard/create", to: "api_keys#create", as: :api_keys_create
  get "dashboard/:id/revoke", to: "api_keys#update", as: :api_keys_revoke
  patch "dashboard/:id/revoke", to: "api_keys#revoke"

  if TradeTariffDevHub.deletion_enabled?
    get "dashboard/:id/delete", to: "api_keys#update", as: :api_keys_delete
    delete "dashboard/:id/delete", to: "api_keys#delete"
  end

  namespace :user_verification do
    resources :steps, only: %i[show update index] do
      collection do
        get :completed
      end
    end
  end

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
