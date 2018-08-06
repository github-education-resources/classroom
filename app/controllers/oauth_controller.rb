# frozen_string_literal: true

class OauthController < ApplicationController
  skip_before_action :authenticate_user!, only: :access_token
  skip_before_action :verify_authenticity_token, only: :access_token

  def authorize
    code = current_user.api_token
    code_param = { code: code }.to_param
    redirect_to URI.encode("x-github-classroom://?#{code_param}")
  end

  def access_token
    if params[:code].present?
      if (user_id = parse_user_id(params[:code]))
        return render json: {
          access_token: api_token(user_id)
        }
      end
    end
    not_found
  end

  private

  def api_token(user_id)
    MessageVerifier.encode({ user_id: user_id }, 24.hours.from_now)
  end

  def parse_user_id(code)
    data = MessageVerifier.decode(code)
    return data[:user_id] unless data.nil?
    nil
  end
end
