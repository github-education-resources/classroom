require 'rails_helper'

describe NullAssignmentInvitation do
  it 'exposes the same public interface as AssignmentInvitation' do
    expect(described_class).to match_the_interface_of AssignmentInvitation
  end
end
