# frozen_string_literal: true
class WebhookController < ApplicationController
  skip_before_action :verify_authenticity_token, :authenticate_user!,
                     :set_organization, :authorize_organization_access

  before_action :verify_organization_presence
  before_action :verify_payload_signature
  before_action :verify_sender_presence

  def events
    case request.headers['X-GitHub-Event']
    when 'ping'
      update_org_hook_status
    when 'push'
      verify_repo_presence
      handle_push_event
    else
      render nothing: true, status: 200
    end
  end

  private

  def verify_sender_presence
    @sender ||= User.find_by(uid: params.dig(:sender, :id))
    not_found unless @sender.present?
  end

  def verify_organization_presence
    @organization ||= Organization.find_by(github_id: params.dig(:organization, :id))
    not_found unless @organization.present?
  end

  def verify_payload_signature
    algorithm, signature = request.headers['X-Hub-Signature'].split('=')

    payload_validated = OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new(algorithm),
                                                ENV['WEBHOOK_SECRET'],
                                                request.body.read) == signature
    not_found unless payload_validated
  end

  def update_org_hook_status
    unless @organization.is_webhook_active?
      @organization.update_attributes(is_webhook_active: true)
    end
    render nothing: true, status: 200
  end

  def verify_repo_presence
    repo_id = params.dig(:repository, :id)
    @assignment_repo ||= AssignmentRepo.find_by(github_repo_id: repo_id)
    @assignment_repo ||= GroupAssignmentRepo.find_by(github_repo_id: repo_id)
    not_found unless @assignment_repo.present?
  end

  def repo_default_branch
    params.dig(:repository, :default_branch)
  end

  def handle_push_event
    case params[:ref]
    when "refs/heads/#{repo_default_branch}"
      create_assignment_submission
    else
      render nothing: true, status: 200
    end
  end

  def create_assignment_submission
    return render nothing: true, status: 200 unless should_create_submission?
    client = @sender.github_client
    github_repo = GitHubRepository.new(client, @assignment_repo.github_repo_id)
    tag_name = "classroom/submission/#{Time.now.to_i}"
    github_repo.create_release(tag_name, default_submission_release_options)
    render nothing: true, status: 200
  end

  def default_submission_release_options
    {
      name: 'Classroom Assignment Submission',
      target_commitish: params.dig(:head_commit, :id)
    }
  end

  def should_create_submission?
    @assignment_repo.starter_code_repo_id.present? ? !params[:created] : true
  end
end
