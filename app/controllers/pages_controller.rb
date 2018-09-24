# frozen_string_literal: true

class PagesController < ApplicationController
  include I18nHelper

  layout :resolve_layout

  skip_before_action :authenticate_user!

  def home
    @teacher_count = User.last.id if User.last

    assignment_repo_count = AssignmentRepo.last.id if AssignmentRepo.last
    group_assignment_repo_count = GroupAssignmentRepo.last.id if GroupAssignmentRepo.last
    @repo_count = assignment_repo_count + group_assignment_repo_count

    return redirect_to organizations_path if logged_in?

    render :homev2 if assistant_landing_page_enabled?
  end

  def assistant
    return not_found unless assistant_landing_page_enabled?
  end

  private

  def resolve_layout
    return "layouts/pagesv2" if assistant_landing_page_enabled?

    "layouts/pages"
  end
end
