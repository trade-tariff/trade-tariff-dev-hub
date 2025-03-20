Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "healthcheckz" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "homepage#index"

  get "dashboard", to: "api_keys#index", as: :api_keys
  get "dashboard/new", to: "api_keys#new", as: :api_keys_new
  post "create", to: "api_keys#create", as: :api_keys_create
  get "dashboard/create", to: "api_keys#show", as: :api_keys_show
  get "dashboard/:id/revoke", to: "api_keys#update", as: :api_keys_update_revoke
  patch "/:id/revoke", to: "api_keys#revoke", as: :api_keys_revoke
  get "dashboard/:id/delete", to: "api_keys#update", as: :api_keys_update_delete
  delete "/:id/delete", to: "api_keys#delete", as: :api_keys_delete

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
