require 'rails_helper'

RSpec.describe InviteStatus, type: :model do
  subject { InviteStatus }

  it "has a default status of unaccepted" do
    invite_status = subject.create()
    expect(invite_status.unaccepted?).to be_truthy
  end
end
