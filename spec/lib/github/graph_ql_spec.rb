# frozen_string_literal: true

require 'rails_helper'

describe GitHub::GraphQL do
  subject { described_class }

  describe '#schema', :vcr do
    it 'parses the JSON and returns a schema' do
      expect(subject.schema).to be_kind_of(GraphQL::Schema)
    end
  end

  describe '#parse', :vcr do
    context 'when the query is valid' do
      let(:query){
        <<-'GRAPHQL'
          query {
            rateLimit {
              remaining
            }
          }
        GRAPHQL
      }

      it 'returns a definition' do
        expect(subject.parse(query)).to be_kind_of(GraphQL::Client::OperationDefinition)
      end
    end

    context 'when the query is invalid' do
      let(:query) { 'I am not a query' }

      it 'raises ParseError' do
        expect {
          subject.parse(query)
        }.to raise_error GitHub::GraphQL::ParseError
      end
    end
  end
end
