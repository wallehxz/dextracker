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
      resources :markets
    end
    resources :announces
    resources :climaxes do
      member do
        get 'sync_volumes'
        get 'timeline'
      end
    end
    resources :launchpads do
      member do
        get 'deploy'
      end
    end
    resources :markets do
      resources :orders do
        member do
          get 'push'
        end
      end
      resources :trades do
        collection do
          get 'pull'
        end
      end
      resources :periods do
        member do
          get 'trades'
        end
        collection do
          get 'grand'
          get 'reset'
        end
      end
    end

    resources :dashboards do
      collection do
        get 'bnb_rate'
        get 'ftx_rate'
      end
    end

    patch "market/:market_id/order_bid/:id", to: "orders#update", as: :market_order_bid
    patch "market/:market_id/order_ask/:id", to: "orders#update", as: :market_order_ask

    Exchange.exchanges.each do |exchange|
      patch "/#{exchange.pluralize}/:id", to: "exchanges#update", as: exchange.to_sym
      patch "/#{exchange.pluralize}/:exchange_id/accounts/:id", to: "accounts#update", as: "#{exchange}_account"
      patch "/#{exchange.pluralize}/:exchange_id/markets/:id", to: "markets#update", as: "#{exchange}_market"
      post  "/#{exchange.pluralize}/:exchange_id/markets", to: "markets#create", as: "#{exchange}_markets"
    end
  end

end

# https://doc.bccnsoft.com/docs/rails-guides-4.1-cn/routing.html
