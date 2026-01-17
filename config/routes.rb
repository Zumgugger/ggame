Rails.application.routes.draw do
    # Redirect authenticated admin users to the main page - doesnt work!
    authenticated :user, ->(user) { user.admin? } do
      root to: "events#main", as: :main_path
    end

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self)
  devise_for :users
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  get "manifest" => "rails/pwa#manifest", as: :pwa_manifest


  # Custom routes added by me
  namespace :ggame do
    resources :uploads, only: [ :index, :create ]
    resources :resets, only: [ :index ] do
      collection do
        put :reset_group_points  # This is what generates reset_group_points_path
        delete :destroy_all_users
        delete :destroy_all_groups
        delete :destroy_all_events
        put :reset_mines
        put :reset_count
        put :reset_kopfgeld
      end
    end
  end

  # API routes for mobile PWA
  namespace :api do
    resources :player_sessions, only: [ :create ] do
      collection do
        get :join
        patch :update_activity
      end
    end
  end

  # Player PWA routes
  get "/join/:token", to: "play#join", as: "join_group"
  post "/join/:token", to: "play#process_join"
  get "/play", to: "play#home", as: "play_home"
  get "/play/targets", to: "play#targets", as: "play_targets"
  get "/play/rules", to: "play#rules", as: "play_rules"

  resources :events
  get "/main", controller: "events", action: :main
  get "/groups/:id/qr_pdf", to: "events#group_qr_pdf", as: "group_qr_pdf"
  get "/", controller: "events", action: :main
end
