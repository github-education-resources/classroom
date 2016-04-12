require 'rails_helper'

RSpec.describe NullGitHubTeam do
  it_behaves_like 'a NullGitHubResource descendant with attributes'

  subject { described_class.new }

  describe '#name' do
    it 'returns Deleted team' do
      expect(subject.name).to eql('Deleted team')
    end
  end

  describe '#slug' do
    it 'returns ghost' do
      expect(subject.slug).to eql('ghost')
    end
  end
end
