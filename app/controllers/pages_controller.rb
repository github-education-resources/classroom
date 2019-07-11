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

  # rubocop:disable AbcSize
  def home
    return redirect_to organizations_path if logged_in?

    @teacher_count = User.last.id if User.last

    if AssignmentRepo.last && GroupAssignmentRepo.last.id
      @repo_count = AssignmentRepo.last.id + GroupAssignmentRepo.last.id
    end

    render layout: "layouts/pages"
  end
  # rubocop:enable AbcSize

  def assistant
    render layout: "layouts/pages"
  end

  def help
    file_name = params[:article_name] ? params[:article_name] : "help"
    return not_found unless HELP_DOCUMENTS.include? file_name

    @file = File.read(Rails.root.join("docs", "#{file_name}.md"))

    @breadcrumbs = [["/", "Classroom"], ["/help", "Help"]]
    @breadcrumbs.push(["", file_name]) if file_name != "help"

    render layout: "layouts/pages"
  rescue Errno::ENOENT
    return not_found
  end
end
