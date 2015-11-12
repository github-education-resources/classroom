module ImpersonationHelper
  def impersonating?(current_user, true_user)
    current_user != true_user
  end
end
