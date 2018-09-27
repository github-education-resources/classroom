# frozen_string_literal: true

require "rails_helper"

describe GitHub::Errors do
  subject { described_class }

  describe "#with_error_handling" do
    describe "failbot" do
      before(:each) do
        Failbot.reports.clear
      end

      it "reports 1 report after 1 failed request" do
        expect(GitHubClassroom.statsd).to receive(:increment).with("github.error.Forbidden")
        begin
          GitHub::Errors.with_error_handling do
            raise Octokit::Forbidden
          end
        rescue GitHub::Forbidden; end # rubocop:disable Lint/HandleExceptions
      end
    end

    context "Octokit::Forbidden is raised" do
      it "raises GitHub::Forbidden" do
        error_message = "You are forbidden from performing this action on github.com"

        expect do
          GitHub::Errors.with_error_handling do
            raise Octokit::Forbidden
          end
        end.to raise_error(GitHub::Forbidden, error_message)
      end
    end

    context "Octokit::NotFound is raised" do
      before(:each) do
        Failbot.reports.clear
      end

      it "raises GitHub::NotFound" do
        error_message = "Resource could not be found on github.com"

        expect do
          GitHub::Errors.with_error_handling do
            raise Octokit::NotFound
          end
        end.to raise_error(GitHub::NotFound, error_message)
      end

      it "does not report a NotFound error" do
        begin
          GitHub::Errors.with_error_handling do
            raise Octokit::NotFound
          end
        rescue GitHub::NotFound; end # rubocop:disable Lint/HandleExceptions
        expect(Failbot.reports.count).to eq(0)
      end
    end

    context "Octokit::ServerError is raised" do
      it "raises GitHub::Error" do
        error_message = "There seems to be a problem on github.com, please try again."

        expect do
          GitHub::Errors.with_error_handling do
            raise Octokit::ServerError
          end
        end.to raise_error(GitHub::Error, error_message)
      end
    end

    context "Octokit::Forbidden is raised" do
      it "raises GitHub::Forbidden" do
        error_message = "You are forbidden from performing this action on github.com"

        expect do
          GitHub::Errors.with_error_handling do
            raise Octokit::Unauthorized
          end
        end.to raise_error(GitHub::Forbidden, error_message)
      end
    end
  end
end
