# frozen_string_literal: true

class PagesController < ApplicationController
  include I18nHelper

  layout "layouts/pages"

  skip_before_action :authenticate_user!

  HELP_DOCUMENTS = [
    "create-group-assignments",
    "help",
    "probot-settings",
    "upgrade-your-organization"
  ].freeze

  def home
    return redirect_to organizations_path if logged_in?

    render :homev2, layout: "layouts/pagesv2" if public_home_v2_enabled?
  end

  def homev2
    @teacher_count = User.last.id if User.last

    if AssignmentRepo.last && GroupAssignmentRepo.last.id
      @repo_count = AssignmentRepo.last.id + GroupAssignmentRepo.last.id
    end

    return not_found unless home_v2_enabled?
    render layout: "layouts/pagesv2"
  end

  def assistant
    render layout: "layouts/pagesv2"
  end

  def help
    file_name = params[:article_name] ? params[:article_name] : "help"
    return not_found unless HELP_DOCUMENTS.include? file_name

    @file = File.read(Rails.root.join("docs", "#{file_name}.md"))

    @breadcrumbs = [["/", "Classroom"], ["/help", "Help"]]
    @breadcrumbs.push(["", file_name]) if file_name != "help"

    render layout: "layouts/pagesv2"
  rescue Errno::ENOENT
    return not_found
  end
end
