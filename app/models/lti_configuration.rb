class LtiConfiguration < ApplicationRecord
  has_one :organization, dependent: :destroy

end
