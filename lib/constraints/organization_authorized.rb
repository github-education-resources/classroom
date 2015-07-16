module Constraints
  class OrganizationAuthorized
    def matches?(request)
      org_id = request.path_info.scan(/\d+/).first
      return true unless org_id
      organization           = Organization.find_by(id: org_id)
      request.session[:init] = true

      organization.users.find_by(id: request.session[:user_id])
    end
  end
end
