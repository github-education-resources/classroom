# frozen_string_literal: true

require 'rails_helper'

describe GitHub::Event do
  let(:organization)  { classroom_org     }
  let(:user)          { classroom_teacher }

  subject { described_class.new(user.token) }

  describe '#latest_push_event', :vcr do
    it 'queries the github events api' do
      repo_id = 8514 # 8514 is rails/rails
      search_url = "repositories/#{repo_id}/events?page=1&per_page=100"
      subject.latest_push_event(8514)

      expect(WebMock).to have_requested(:get, github_url(search_url))
    end
  end
end
