# frozen_string_literal: true

require "rails_helper"

# This exception initializer crashes if it isn't thrown from the serializer...
# so let's override it.
module ActiveJob
  class DeserializationError
    def initialize; end
  end
end

RSpec.describe Assignment::RepositoryVisibilityJob, type: :job do
  subject { Assignment::RepositoryVisibilityJob }

  context "when a serialization error is thrown" do
    it "does not crash the test" do
      allow_any_instance_of(subject).to receive(:perform) { raise ActiveJob::DeserializationError }

      subject.perform_now(double, change: {})
    end
  end

  context "when a different error is thrown" do
    it "crashes the test" do
      allow_any_instance_of(subject).to receive(:perform) { raise StandardError }

      expect do
        subject.perform_now(double, change: {})
      end.to raise_error(StandardError)
    end
  end
end
