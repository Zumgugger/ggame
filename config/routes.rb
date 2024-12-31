Rails.application.routes.draw do
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

  # Defines the root path route ("/")
  # changed by me
  root to: "home#index" # Or any other controller/view you prefer

  # Custom routes added by me
  namespace :ggame do
    resources :uploads, only: [ :index, :create ]
    resources :resets, only: [ :index ] do
      collection do
        post :reset_group_points  # This is what generates reset_group_points_path
        delete :destroy_all_users
        delete :destroy_all_groups
        put :reset_mines
        put :reset_count
      end
    end
  end
end
