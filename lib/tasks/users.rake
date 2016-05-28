namespace :users do
  desc "Find all teachers that don't have the correct scopes"
  task find_deficient_organization_scopes: :environment do
    Rails.logger = Logger.new(STDOUT)

    count = OrganizationsUser.count
    progress_bar = ProgressBar.create(
      title: "Searching #{ActionController::Base.helpers.pluralize(count, 'record')}...",
      total: count
    )

    OrganizationsUser.includes(:organization, :user).all.each do |organizations_user|
      progress_bar.increment

      begin
        organization = organizations_user.organization
        user         = organizations_user.user

        next if (Classroom::Scopes::TEACHER - user.github_client_scopes).empty?

        puts "User #{user.id} for Organization #{organization.id}"
      rescue => e
        puts e
      end
    end
  end
end
