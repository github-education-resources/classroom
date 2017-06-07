# frozen_string_literal: true

require 'rails_helper'

describe GitHub::Token do
  subject { described_class }

  let(:student) { classroom_student }

  describe '#scopes', :vcr do
    it 'returns the scopes of the token in an array' do
      expect(described_class.scopes(student.token)).to be_kind_of(Array)
    end
  end

  describe '#expand_scopes', :vcr do
    it 'converts scopes to their expanded form correctly' do
      scope_list = ['test', 'user', 'repo', 'admin:org', 'admin:public_key', 'admin:repo_hook', 'admin:gpg_key']
      expected_expanded = [
        'test',
        'read:user', 'user:email', 'user:follow',
        'repo:status', 'repo_deployment', 'public_repo',
        'write:org', 'read:org',
        'write:public_key', 'read:public_key',
        'write:repo_hook', 'read:repo_hook',
        'write:gpg_key', 'read:gpg_key'
      ]

      expect(described_class.expand_scopes(scope_list)).to eq(expected_expanded)
    end
  end
end
