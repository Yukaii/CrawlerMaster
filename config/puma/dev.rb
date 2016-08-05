#!/usr/bin/env puma

rails_root = `pwd`.gsub("\n", "")
directory rails_root

rails_env = ENV['RAILS_ENV'] || 'development'
environment rails_env

threads 2, 8
workers 2

daemonize true
state_path           "#{rails_root}/tmp/pids/puma.state"
pidfile              "#{rails_root}/tmp/pids/puma.pid"
stdout_redirect      "#{rails_root}/log/puma.access.log", "#{rails_root}/log/puma.error.log"
bind                 "tcp://0.0.0.0:9292"
#bind                 "unix://#{rails_root}/tmp/puma/sock"
#activate_control_app "unix://#{rails_root}/tmp/puma/ctlsock"

preload_app!
