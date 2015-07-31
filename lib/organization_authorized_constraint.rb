class OrganizationAuthorizedConstraint
  def matches?(request)
    org_id       = request.path_info.scan(/\d+/).first
    organization = Organization.find_by(id: org_id)

    return true unless organization

    user = User.find(request.session[:user_id])
    organization.users.include?(user) || user.staff?
  end
end
