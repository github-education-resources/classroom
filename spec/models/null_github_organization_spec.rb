require 'rails_helper'

RSpec.describe NullGitHubOrganization do
  subject { described_class.new }

  describe '#html_url' do
    it 'returns #' do
      expect(subject.html_url).to eql('#')
    end
  end

  describe '#login' do
    it 'returns ghost' do
      expect(subject.login).to eql('ghost')
    end
  end

  describe '#name' do
    it 'returns Deleted organization' do
      expect(subject.name).to eql('Deleted organization')
    end
  end

  describe '#null?' do
    it 'returns true' do
      expect(subject.null?).to be(true)
    end
  end
end
