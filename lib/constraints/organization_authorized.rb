module Constraints
  class OrganizationAuthorized
    def matches?(request)
      org_id       = request.path_info.scan(/\d+/).first
      organization = Organization.find_by(id: org_id)

      return true unless organization

      request.session[:init] = true
      organization.users.find_by(id: request.session[:user_id])
    end
  end
end
