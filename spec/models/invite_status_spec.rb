# frozen_string_literal: true

require "rails_helper"

RSpec.describe InviteStatus, type: :model do
  subject { InviteStatus }

  it "has a default status of unaccepted" do
    invite_status = subject.create
    expect(invite_status.unaccepted?).to be_truthy
  end

  it "is errored? when errored_creating_repo?" do
    invite_status = subject.create
    invite_status.errored_creating_repo!
    expect(invite_status.errored?).to be_truthy
  end

  it "is errored? when errored_importing_starter_code?" do
    invite_status = subject.create
    invite_status.errored_importing_starter_code!
    expect(invite_status.errored?).to be_truthy
  end

  it "is errored? only when errored_creating_repo? or errored_importing_starter_code?" do
    invite_status = subject.create
    non_errored_statuses = subject.statuses.keys.reject do |status|
      status == "errored_creating_repo" || status == "errored_importing_starter_code"
    end
    non_errored_statuses.each do |status|
      invite_status.update(status: status)
      expect(invite_status.errored?).to be_falsey
    end
  end
end
