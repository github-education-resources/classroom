# frozen_string_literal: true

class OauthController < ApplicationController
  prepend_before_action :ensure_download_repositories_flipper_is_enabled, except: :access_token
  prepend_before_action :ensure_download_repositories_flipper_is_enabled_globally, only: :access_token

  skip_before_action :authenticate_user!, only: :access_token
  skip_before_action :verify_authenticity_token, only: :access_token

  def authorize
    not_found if params[:redirect_uri].blank?
    code = current_user.api_token
    code_param = { code: code }.to_param
    redirect_to "#{params[:redirect_uri]}?#{code_param}"
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
    JsonWebToken.encode({ user_id: user_id }, 24.hours.from_now)
  end

  def parse_user_id(code)
    data = JsonWebToken.decode(code)
    unless data.nil?
      return data[:user_id]
    end
    nil
  end
end
