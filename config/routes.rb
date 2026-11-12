Rails.application.routes.draw do
  resources :tasks, only: %i[ index create update destroy ]
  resources :categories, except: [ :show ]
  resources :tags, except: [ :show ]
  # 旧 Todo の URL から来た場合
  get "todos", to: redirect { |_params, request| "#{request.script_name}/tasks" }

  get "sign_up", to: "registrations#new", as: :sign_up
  post "registrations/options", to: "registrations#options", as: :registration_options
  post "registrations", to: "registrations#create", as: :registrations

  get "sign_in", to: "sessions#new", as: :sign_in
  delete "sign_out", to: "sessions#destroy", as: :sign_out
  post "sessions/options", to: "sessions#options", as: :session_options
  post "sessions", to: "sessions#create", as: :sessions

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "tasks#index"
end
