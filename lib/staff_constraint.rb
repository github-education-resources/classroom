class StaffConstraint
  def matches?(request)
    return false unless request.session[:user_id]
    user = User.find(request.session[:user_id])
    user && user.staff?
  end
end
