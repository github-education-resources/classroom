source 'https://rubygems.org'

ruby '2.2.2'
gem 'rails', '4.2.3'

gem 'autoprefixer-rails'

gem 'coffee-rails', '~> 4.1.0'

gem 'faraday-http-cache'

gem 'octokit'
gem 'omniauth'
gem 'omniauth-github'

gem 'pg'
gem 'pundit'

gem 'sass-rails', '~> 5.0'

gem 'turbolinks'

gem 'uglifier', '>= 1.3.0'

group :development do
  gem 'better_errors'
  gem 'binding_of_caller'
  gem 'rails-erd', require: false
  gem 'quiet_assets'
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
  gem 'puma'
  gem 'rails_12factor'
end

group :test do
  gem 'factory_girl_rails'
  gem 'faker'
  gem 'vcr'
  gem 'webmock'
end
