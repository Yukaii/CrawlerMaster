# Puma config
# https://github.com/puma/puma/blob/master/examples/config.rb
directory '/home/deploy/colorgy_crawler/current'

workers Integer(ENV['PUMA_WORKERS'] || 1)
threads Integer(ENV['PUMA_MIN_THREADS']  || 4), Integer(ENV['PUMA_MAX_THREADS'] || 16)

preload_app!

rackup      DefaultRackup
port        ENV['PORT']     || 3000
environment ENV['RACK_ENV'] || 'development'

stdout_redirect '/home/deploy/colorgy_crawler/shared/log/puma_access.log',
                '/home/deploy/colorgy_crawler/shared/log/puma_error.log', true
pidfile         '/home/deploy/colorgy_crawler/shared/tmp/pids/puma.pid'
state_path      '/home/deploy/colorgy_crawler/shared/tmp/pids/puma.state'
bind     'unix:///home/deploy/colorgy_crawler/shared/tmp/sockets/puma.sock'

on_worker_boot do
  # Worker specific setup for Rails
  ActiveSupport.on_load(:active_record) do
    config = ActiveRecord::Base.configurations[Rails.env] ||
               Rails.application.config.database_configuration[Rails.env]
    config['pool'] = ENV['PUMA_MAX_THREADS'] || 16
    ActiveRecord::Base.establish_connection(config)
  end
end
