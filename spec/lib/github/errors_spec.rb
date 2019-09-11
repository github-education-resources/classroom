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

    context "Failbot reporting" do
      let(:error_message) { "You are forbidden from performing this action on github.com" }

      before(:each) do
        Failbot.reports.clear
      end

      context "report_to_failbot is true" do
        it "reports to Failbot" do
          expect do
            GitHub::Errors.with_error_handling(report_to_failbot: true) do
              raise Octokit::Forbidden
            end
          end.to raise_error(GitHub::Forbidden, error_message)
          expect(Failbot.reports.count).to be > 0
        end
      end

      context "report_to_failbot is not passed" do
        it "reports to Failbot by default" do
          expect do
            GitHub::Errors.with_error_handling do
              raise Octokit::Forbidden
            end
          end.to raise_error(GitHub::Forbidden, error_message)
          expect(Failbot.reports.count).to be > 0
        end
      end

      context "report_to_failbot is false" do
        it "does not report to Failbot" do
          expect do
            GitHub::Errors.with_error_handling(report_to_failbot: false) do
              raise Octokit::Forbidden
            end
          end.to raise_error(GitHub::Forbidden, error_message)
          expect(Failbot.reports.count).to be_zero
        end
      end
    end
  end
end
