source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?('/')
  "https://github.com/#{repo_name}.git"
end

ruby '2.4.0'
gem 'rails', '~> 5.0', '>= 5.0.2'

gem 'autoprefixer-rails'

gem 'chewy', '~> 0.9.0'

gem 'dalli'

gem 'faraday-http-cache'
gem 'flipper'
gem 'flipper-redis'
gem 'flipper-ui'

gem 'geo_pattern'

gem 'jbuilder'
gem 'jquery-turbolinks'

gem 'kaminari'

gem 'local_time'

gem 'octicons_helper', '~> 2.1'
gem 'octokit', github: 'octokit/octokit.rb', ref: '207fb98100cf65d486e41156630ffa9288f297b3'
gem 'omniauth'
gem 'omniauth-github'

gem 'peek', '~> 1.0', '>= 1.0.1'
gem 'peek-dalli'
gem 'peek-gc'
gem 'peek-git'
gem 'peek-performance_bar'
gem 'peek-pg',      github: 'mkcode/peek-pg',      ref: '9bbe212ed1b6b4a4ad56ded1ef4cf9179cdac0cd'
gem 'peek-sidekiq', github: 'Soliah/peek-sidekiq', ref: '261c857578ae6dc189506a35194785a4db51e54c'
gem 'pg'
gem 'pry-byebug'
gem 'pry-rails'
gem 'puma', '~> 3.8', '>= 3.8.2'

gem 'rack-canonical-host'
gem 'rack-timeout', require: false
gem 'rails-i18n', '~> 5.0', '>= 5.0.1'
gem 'redis-namespace'
gem 'ruby-progressbar', '~> 1.8', '>= 1.8.1', require: false

gem 'sass-rails', '~> 5.0', '>= 5.0.6'
gem 'sidekiq',    '~> 4.2', '>= 4.2.10'
gem 'sprockets'

gem 'turbolinks', github: 'turbolinks/turbolinks-classic', ref: '37a7c296232d20a61bd1946f600da7f2009189db'
gem 'typhoeus',   '~> 1.1', '>= 1.1.2'

gem 'uglifier', '>= 1.3.0'

group :development do
  gem 'foreman'
  gem 'web-console'
end

group :development, :test do
  gem 'awesome_print', require: 'ap'
  gem 'bullet'
  gem 'dotenv-rails'
  gem 'guard-rspec', require: false
  gem 'rails-controller-testing'
  gem 'rspec-rails'
  gem 'rubocop', require: false
  gem 'scss_lint', require: false
  gem 'spring'
  gem 'terminal-notifier-guard'
  gem 'timecop', require: false
end

group :production do
  gem 'airbrake'
  gem 'lograge', '~> 0.4.1'
  gem 'newrelic_rpm'
  gem 'pinglish'
  gem 'puma_worker_killer'
  gem 'rack-tracker'
  gem 'rails_12factor'
end

group :test do
  gem 'database_cleaner'
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'simplecov', require: false
  gem 'vcr'
  gem 'webmock'
end
