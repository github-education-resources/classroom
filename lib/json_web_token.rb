# frozen_string_literal: true

class JsonWebToken
  class << self
    def encode(payload, exp = 5.minutes.from_now)
      payload[:exp] = exp.to_i
      JWT.encode(payload, jwt_secret)
    end

    def decode(token)
      body = JWT.decode(token, jwt_secret)[0]
      HashWithIndifferentAccess.new body
    rescue StandardError
      nil
    end

    private

    def jwt_secret
      @jwt_secret ||= Rails.application.secrets.jwt_secret
      return @jwt_secret if @jwt_secret.present?

      raise "JWT_SECRET is not set, please check you .env file"
    end
  end
end
