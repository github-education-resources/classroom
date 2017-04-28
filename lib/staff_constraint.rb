# frozen_string_literal: true

class StaffConstraint
  def matches?(request)
    return false unless request.session[:user_id]
    user = User.find(request.session[:user_id])
    user.present? && user.staff?
  end
end
