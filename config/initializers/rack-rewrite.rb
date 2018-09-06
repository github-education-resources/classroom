Rails.application.config.middleware.insert_before(Rack::Runtime, Rack::Rewrite) do
  r301   %r{/desktop/download(.*)},  'http://classroom-desktop-deploy-test.herokuapp.com/download$1'
  r301   %r{/desktop/update(.*)},  'http://classroom-desktop-deploy-test.herokuapp.com/update$1'
end
