Rails.application.routes.draw do
  root 'welcome#index'

  devise_for :users
  devise_scope :user do
    get  'sign_in',          to:'users/sessions#new'
    post 'sign_in',          to:'users/sessions#create'
    get  'sign_up',          to:'users/registrations#new'
    post 'sign_up',          to:'users/registrations#create'
    get  'sign_out',         to:'users/sessions#destroy'
    get  'forgot_password',  to:'users/passwords#new'
    post 'forgot_password',  to:'users/passwords#create'
    get  'reset_password',   to:'users/passwords#edit'
    put  'reset_password',   to:'users/passwords#update'
  end

  namespace :backend do
    root 'exchanges#index'
    resources :exchanges do
      member do
        get 'sync_asset'
        get 'sync_cost'
      end
      resources :snapshots
      resources :accounts
    end

    Exchange.exchanges.each do |exchange|
      patch "/#{exchange.pluralize}/:id", to: "exchanges#update", as: exchange.to_sym
      patch "/#{exchange.pluralize}/:exchange_id/accounts/:id", to: "accounts#update", as: "#{exchange}_account"
    end
  end

end

# https://doc.bccnsoft.com/docs/rails-guides-4.1-cn/routing.html
