Rails.application.configure do
  config.after_initialize do
    if defined? Bullet
      Bullet.enable = true
      Bullet.bullet_logger = true

      if Rails.env.development?
        Bullet.alert = true
        Bullet.console = true
        Bullet.rails_logger = true
        Bullet.add_footer = true
      end

      if Rails.env.test?
        Bullet.raise = true
      end
    end
  end
end
