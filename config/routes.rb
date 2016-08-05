Rails.application.routes.draw do
  get 'courses/index'

  devise_for :admin_users
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'
  root 'crawlers#index'

  scope :crawlers, controller: 'crawlers' do
    get    '/',                  action: :index,          as: :crawlers
    get    ':id',                action: :show,           as: :crawler

    post   ':id/setting',        action: :setting,        as: :setting_crawler
    post   ':id/run',            action: :run,            as: :run_crawler
    post   ':id/sync',           action: :sync,           as: :sync_crawler

    get    ':id/tasks/:task_id',          action: :changes,        as: :task_changes
    post   ':id/tasks/:task_id/snapshot', action: :snapshot,       as: :task_snapshot

    delete ':id/jobs/:jid',      action: :unschedule_job, as: :unschedule_job

    post   'batch_run',          action: :batch_run,      as: :batch_run_crawler
  end

  get 'courses' => 'courses#index', as: :courses

  # Sidekiq
  require 'sidekiq/web'
  authenticate :admin_user do
    mount Sidekiq::Web => '/sidekiq'
  end

end
