# frozen_string_literal: true

require 'rails_helper'

# GraphQL definitions are required to be static constants, so I'm defining this here
# (the lib throws an exception if it's not)
SIMPLE_DEF = GitHub::GraphQL.parse <<-'GRAPHQL'
  query {
    repository(owner: "rails", name: "rails") {
      nameWithOwner
    }
  }
GRAPHQL

describe GitHub::GraphQL::Client, :vcr do
  let(:user) { classroom_teacher }

  describe '#query' do
    context 'with no token' do
      let(:client) { described_class.new(token: nil) }

      it 'returns QueryError' do
        expect {
          client.query(SIMPLE_DEF)
        }.to raise_error GitHub::GraphQL::QueryError
      end
    end

    context 'with a bad token' do
      let(:client) { described_class.new(token: 'spaghetti') }

      it 'returns QueryError' do
        expect {
          client.query(SIMPLE_DEF)
        }.to raise_error GitHub::GraphQL::QueryError
      end
    end

    context 'with a valid token' do
      let(:client) { described_class.new(token: user.token) }

      it 'returns rails/rails' do
        result = client.query(SIMPLE_DEF)

        expect(result.repository.name_with_owner).to eq('rails/rails')
      end
    end
  end
end
