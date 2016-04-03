require 'rails_helper'

RSpec.describe NullGitHubRepository do
  it_behaves_like 'a NullGitHubResource descendant with attributes'

  subject { described_class.new }

  describe '#full_name' do
    it 'returns Deleted repository' do
      expect(subject.full_name).to eql('Deleted repository')
    end
  end

  describe '#html_url' do
    it 'returns #' do
      expect(subject.html_url).to eql('#')
    end
  end
end
