require 'rails_helper'

RSpec.describe LtiConfiguration, type: :model do
  it { should belong_to(:organization) } 
end
