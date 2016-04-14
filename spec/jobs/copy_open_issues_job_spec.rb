require 'rails_helper'

RSpec.describe CopyOpenIssuesJob, type: :job do
  let(:student) { GitHubFactory.create_classroom_student }

  describe 'the job', :vcr do
    it 'gets the the open issues from the source repository' do
      source_repo_id = 1
      destination_repo_id = 54_747_927
      CopyOpenIssuesJob.perform_now(student, source_repo_id, destination_repo_id)
      list_issues_request = "/repositories/#{source_repo_id}/issues?direction=asc&per_page=100&sort=created"
      expect(WebMock).to have_requested(:get, github_url(list_issues_request))
    end

    it 'creates corresponding issues in the destination repository' do
      # expect a post request to "/repositories/#{destination_repo_id}/issues"
      # for each issue returned in the response of the previous request
    end
  end
end
