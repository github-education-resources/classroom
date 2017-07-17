# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnlinkedUser::ShowView do
  let(:unlinked_user) { classroom_student }

  subject { UnlinkedUser::ShowView.new(unlinked_user: unlinked_user) }

  describe "#github_handle_text", :vcr do
    it "returns the login prefaced by a @" do
      expect(subject.github_handle_text).to eq("@#{unlinked_user.github_user.login}")
    end
  end
end
