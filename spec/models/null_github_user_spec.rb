require 'rails_helper'

RSpec.describe NullGitHubUser do
  it_behaves_like 'a NullGitHubResource descendant with attributes'

  subject { described_class.new }

  describe '#html_url' do
    it 'returns #' do
      expect(subject.html_url).to eql('https://github.com/ghost')
    end
  end

  describe '#login' do
    it 'returns ghost' do
      expect(subject.login).to eql('ghost')
    end
  end

  describe '#name' do
    it 'returns Deleted user' do
      expect(subject.name).to eql('Deleted user')
    end
  end
end
