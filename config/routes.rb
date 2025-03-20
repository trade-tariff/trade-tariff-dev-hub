Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "homepage#index"

  match '/400', to: 'errors#bad_request', via: :all
  match '/404', to: 'errors#not_found', via: :all, as: :not_found
  match '/405', to: 'errors#method_not_allowed', via: :all
  match '/406', to: 'errors#not_acceptable', via: :all
  match '/422', to: 'errors#unprocessable_entity', via: :all
  match '/429', to: 'errors#too_many_requests', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
  match '/501', to: 'errors#not_implemented', via: :all
  match '/503', to: 'errors#maintenance', via: :all
  match '*path', to: 'errors#not_found', via: :all
end
