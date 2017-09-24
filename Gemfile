# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby File.read(File.expand_path("../.ruby-version", __FILE__)).chomp
gem "rails", "~> 5.1", ">= 5.1.3"

gem "autoprefixer-rails", "~> 7.1", ">= 7.1.3"

gem "bootsnap", "~> 1.1", ">= 1.1.2", require: false

gem "chewy", "~> 0.10.1"
gem "connection_pool", "~> 2.2", ">= 2.2.1"

gem "dalli", "~> 2.7", ">= 2.7.6"

gem "failbot_rails",      "~> 0.5.0"
gem "faraday-http-cache", "~> 2.0"
gem "flipper",            "~> 0.10.2"
gem "flipper-redis",      "~> 0.10.2"
gem "flipper-ui",         "~> 0.10.2"

gem "geo_pattern", "~> 1.4"

gem "jquery-datetimepicker-rails", "~> 2.4", ">= 2.4.1.0"
gem "jquery-turbolinks",           "~> 2.1"

gem "kaminari", "~> 1.0", ">= 1.0.1"

gem "local_time", "~> 2.0"

gem "octicons_helper", "~> 2.1"
gem "octokit",         "~> 4.7"
gem "omniauth",        "~> 1.6", ">= 1.6.1"
gem "omniauth-github", "~> 1.3"

gem "peek",                 "~> 1.0", ">= 1.0.1"
gem "peek-dalli",           github: "peek/peek-dalli", ref: "0a68e1fc73095a421dc2cae3d23937bb1cbb027c"
gem "peek-gc",              "~> 0.0.2"
gem "peek-git",             "~> 1.0", ">= 1.0.2"
gem "peek-performance_bar", "1.2"
gem "peek-pg",              github: "mkcode/peek-pg",      ref: "9bbe212ed1b6b4a4ad56ded1ef4cf9179cdac0cd"
gem "peek-sidekiq",         github: "Soliah/peek-sidekiq", ref: "261c857578ae6dc189506a35194785a4db51e54c"
gem "pg",                   "~> 0.21.0"
gem "pry-byebug",           "~> 3.5"
gem "pry-rails",            "~> 0.3.6"
gem "puma",                 "~> 3.10"

gem "rack-canonical-host", "~> 0.2.3"
gem "rack-timeout",        "~> 0.4.2", require: false
gem "rails-i18n",          "~> 5.0", ">= 5.0.1"
gem "redis-namespace",     "~> 1.5", ">= 1.5.3"
gem "ruby-progressbar",    "~> 1.8", require: false

gem "sass-rails", "~> 5.0", ">= 5.0.6"
gem "sidekiq",    "~> 5.0", ">= 5.0.4"
gem "sprockets",  "~> 3.7", ">= 3.7.1"

gem "turbolinks", github: "turbolinks/turbolinks-classic", ref: "37a7c296232d20a61bd1946f600da7f2009189db"
gem "typhoeus",   "~> 1.3"

gem "uglifier", "~> 3.2"

group :development do
  gem "foreman",     "~> 0.84.0"
  gem "web-console", "~> 3.5", ">= 3.5.1"
end

group :development, :test do
  gem "awesome_print",            "~> 1.8", require: "ap"
  gem "bullet",                   "~> 5.6", ">= 5.6.1"
  gem "dotenv-rails",             "~> 2.2", ">= 2.2.1"
  gem "guard-rspec",              "~> 4.7", ">= 4.7.3", require: false
  gem "knapsack",                 "~> 1.14", ">= 1.14.1"
  gem "rails-controller-testing", "~> 1.0", ">= 1.0.2"
  gem "rspec-rails",              "~> 3.6", ">= 3.6.1"
  gem "rubocop",                  "~> 0.49.1", require: false
  gem "scss_lint",                "~> 0.54.0", require: false
  gem "spring",                   "~> 2.0", ">= 2.0.2"
  gem "spring-watcher-listen",    "~> 2.0", ">= 2.0.1"
  gem "terminal-notifier-guard",  "~> 1.7"
  gem "timecop",                  "~> 0.9.1", require: false
end

group :production do
  gem "airbrake",           "~> 6.2", ">= 6.2.1"
  gem "dogstatsd-ruby",     "~> 3.0"
  gem "lograge",            "~> 0.6.0"
  gem "newrelic_rpm",       "~> 4.4", ">= 4.4.0.336"
  gem "pinglish",           "~> 0.2.1"
  gem "puma_worker_killer", "~> 0.1.0"
  gem "rack-tracker",       "~> 1.4"
end

group :test do
  gem "database_cleaner",   "~> 1.6", ">= 1.6.1"
  gem "factory_girl_rails", "~> 4.8"
  gem "faker",              "~> 1.8", ">= 1.8.4"
  gem "simplecov",          "~> 0.15.0", require: false
  gem "vcr",                "~> 3.0", ">= 3.0.3"
  gem "webmock",            "~> 3.0", ">= 3.0.1"
end
