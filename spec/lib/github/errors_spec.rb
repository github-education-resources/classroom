# frozen_string_literal: true

require "rails_helper"

describe GitHub::Errors do
  subject { described_class }

  describe "#with_error_handling" do
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
  end
end
