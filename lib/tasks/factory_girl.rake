# frozen_string_literal: true

namespace :factory_girl do
  desc "Verify that all FactoryGirl factories are valid"
  task lint: :environment do
    if Rails.env.test?
      begin
        Chewy.strategy(:bypass)
        DatabaseCleaner.start
        FactoryGirl.lint
      ensure
        DatabaseCleaner.clean
      end
    else
      system("bundle exec rake factory_girl:lint RAILS_ENV='test'")
    end
  end
end
