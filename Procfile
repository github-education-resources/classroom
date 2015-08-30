web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -q starter_code,2 -q default -q trash_can
