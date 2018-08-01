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
      data = JsonWebToken.decode(params[:code])
      unless data.nil? || data[:user_id].nil?
        access_token = JsonWebToken.encode({ user_id: data[:user_id] }, 24.hours.from_now)
        return render json: {
          access_token: access_token
        }
      end
    end
    not_found
  end
end

