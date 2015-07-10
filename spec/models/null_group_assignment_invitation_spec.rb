require 'rails_helper'

describe NullGroupAssignmentInvitation do
  it 'exposes the same public interface as GroupAssignmentInvitation' do
    expect(described_class).to match_the_interface_of GroupAssignmentInvitation
  end
end
