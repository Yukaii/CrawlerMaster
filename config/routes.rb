Rails.application.routes.draw do
  get 'courses/index'

  devise_for :admin_users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  root 'crawlers#index'

  get    'crawlers/:id'           => 'crawlers#show'           ,as: :crawler
  post   'crawlers/:id/setting'   => 'crawlers#setting'        ,as: :setting_crawler
  post   'crawlers/:id/run'       => 'crawlers#run'            ,as: :run_crawler
  post   'crawlers/batch_run'     => 'crawlers#batch_run'      ,as: :batch_run_crawler
  post   'crawlers/:id/sync'      => 'crawlers#sync'           ,as: :sync_crawler
  get    'crawlers'               => 'crawlers#index'          ,as: :crawlers
  delete 'crawlers/:id/jobs/:jid' => 'crawlers#unschedule_job' ,as: :unschedule_job

  get 'courses' => 'courses#index', as: :courses

  # Sidekiq
  require 'sidekiq/web'
  authenticate :admin_user do
    mount Sidekiq::Web => '/sidekiq'
  end

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end
end
