source 'https://rubygems.org'

ruby '2.2.3'
gem 'rails', '4.2.4'

gem 'autoprefixer-rails'

gem 'coffee-rails', '~> 4.1.0'

gem 'draper'

gem 'faraday-http-cache'
gem 'friendly_id'

gem 'geo_pattern'

gem 'jbuilder'
gem 'jquery-turbolinks'

gem 'kaminari'

gem 'octokit'
gem 'omniauth'
gem 'omniauth-github'

gem 'pg'

gem 'rack-canonical-host'

gem 'sprockets',  '3.3.1'
gem 'sass-rails', '~> 5.0'
gem 'sidekiq'
gem 'sinatra'

gem 'turbolinks'

gem 'uglifier', '>= 1.3.0'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'foreman'
  gem 'quiet_assets'
end

group :development, :production do
  gem 'peek'
  gem 'peek-dalli'
  gem 'peek-gc'
  gem 'peek-git'
  gem 'peek-performance_bar'
  gem 'peek-pg'
  gem 'peek-sidekiq', github: 'Soliah/peek-sidekiq', ref: '261c857578ae6dc189506a35194785a4db51e54c'
end

group :development, :test do
  gem 'awesome_print', require: 'ap'
  gem 'dotenv-rails'
  gem 'pry-rails'
  gem 'pry-byebug'
  gem 'rspec-rails'
  gem 'rubocop',   require: false
  gem 'scss_lint', require: false
  gem 'spring'
end

group :production do
  gem 'dalli'
  gem 'newrelic_rpm'
  gem 'puma'
  gem 'rack-tracker'
  gem 'rails_12factor'
end

group :test do
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'vcr'
  gem 'webmock'
end
