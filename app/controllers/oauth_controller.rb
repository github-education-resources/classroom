# frozen_string_literal: true

class OauthController < ApplicationController
  skip_before_action :authenticate_user!, only: :access_token
  skip_before_action :verify_authenticity_token

  def authorize
    return unless params[:redirect_uri].present?
    code = JsonWebToken.encode(user_id: current_user.id)
    code_param = { code: code }.to_param
    redirect_to "#{params[:redirect_uri]}?#{code_param}"
  end

  def access_token
    if params[:code].present?
      data = JsonWebToken.decode(params[:code])
      if !data[:user_id].nil?
        return render json: {
          access_token: JsonWebToken.encode(user_id: data[:user_id], exp: 24.hours.from_now)
        }
      end
    end
    log_out
  end
end

