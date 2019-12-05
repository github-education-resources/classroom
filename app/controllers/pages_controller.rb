# frozen_string_literal: true

class PagesController < ApplicationController
  include I18nHelper

  layout "layouts/pages"

  skip_before_action :authenticate_user!

  HELP_DOCUMENTS = [
    "create-group-assignments",
    "help",
    "probot-settings",
    "upgrade-your-organization",
    "using-template-repos-for-assignments",
    "creating-an-individual-assignment",
    "connect-to-lms",
    "generate-lms-credentials",
    "glossary",
    "import-roster-from-lms",
    "setup-generic-lms",
    "setup-canvas",
    "setup-moodle",
    "archive-a-classroom"
  ].freeze

  def home
    return redirect_to organizations_path if logged_in?

    @teacher_count = User.last&.id.to_i
    @repo_count = AssignmentRepo.last&.id.to_i + GroupAssignmentRepo.last&.id.to_i

    render layout: "layouts/pages"
  end

  def assistant
    render layout: "layouts/pages"
  end

  def help
    file_name = params[:article_name] ? params[:article_name] : "help"
    return not_found unless HELP_DOCUMENTS.include? file_name

    @file = File.read(Rails.root.join("docs", "#{file_name}.md"))

    @breadcrumbs = [["/", "GitHub Classroom"], ["/help", "Help"]]
    @breadcrumbs.push(["", file_name]) if file_name != "help"

    render layout: "layouts/pages"
  rescue Errno::ENOENT
    return not_found
  end
end
