web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -q chewy -q trash_can -q github_webhooks -q github_webhook_failures
