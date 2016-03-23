require 'rails_helper'

RSpec.describe OcticonHelper, type: :helper do
  describe '#mega_octicon' do
    it 'returns a mega-octicon span tag' do
      expect(mega_octicon('logo-github')).to eq('<span class="mega-octicon octicon-logo-github"></span>')
    end
  end

  describe '#octicon' do
    it 'returns an octicon span tag' do
      expect(octicon('logo-github')).to eq('<span class="octicon octicon-logo-github"></span>')
    end
  end
end
