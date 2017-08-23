# frozen_string_literal: true

class StafftoolsController < ApplicationController
  layout "stafftools"

  before_action :authorize_access

  private

  def authorize_access
    not_found unless current_user.try(:staff?)
  end
end
