# frozen_string_literal: true
require 'rails_helper'

RSpec.describe StudentIdentifierType, type: :model do
  it_behaves_like 'a default scope where deleted_at is not present'
end
