# frozen_string_literal: true

require "rails_helper"

RSpec.describe RepositorySetupJob, type: :job do
  # ways porter fails
  # 
  # - workers were down
  # - repositories were created

  describe "#perform" do
    it "returns a 200?"

    context "when porter returns a 200" do
      it "sets the status to importing"
    end

    context "when porter fails" do
    end
  end

  describe "#finished?" do
    it "is true if the import is finished"
    it "is false otherwise"
  end
end
