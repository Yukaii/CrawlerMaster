source 'https://rubygems.org'

ruby "2.2.0"

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.2'
# Use sqlite3 as the database for Active Record

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
# gem 'therubyracer', platforms: :ruby
gem 'slim'

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'bootstrap-sass', '~> 3.3.6'

gem "compass-rails", github: "Compass/compass-rails", branch: "master"

gem 'kaminari'

gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

gem 'dotenv-rails'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'
gem 'devise'

# Use Pry as the Rails console
gem 'pry-rails'
gem 'pry-byebug'
gem 'awesome_print', :require => false
gem 'hirb', :require => false
gem 'hirb-unicode', :require => false

# crawler dependencies
gem 'rest-client'
gem 'httpclient', '~> 2.7'
gem 'iconv'
gem 'crawler_rocks'
gem 'hashie'
gem 'capybara'
gem 'poltergeist'
gem 'archive-tar-minitar'
gem 'spreadsheet'
gem 'rtesseract', :require => false
gem 'rmagick', :require => false
gem 'selenium-webdriver'
gem "capybara-webkit"

gem 'sidekiq', '~> 4.0'
gem 'sidekiq-limit_fetch'
gem 'redis-namespace'

gem 'sinatra', :require => nil

gem 'rufus-scheduler', '~> 3.1'

# Use Unicorn as the app server
gem 'unicorn'
# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development
gem 'remote_syslog_logger'

group :development, :test do
    # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'better_errors'
  gem "binding_of_caller"
  gem 'rspec-rails', '~> 3.0'
  gem 'shoulda-matchers', require: false
  gem 'guard-rspec', require: false
  gem 'faker'
  gem "factory_girl_rails", "~> 4.0"
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  gem 'sqlite3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :production do
  gem 'pg'
  gem 'newrelic_rpm'
  gem 'rails_12factor'
end
