# Stores metadata specific to a Cloud IDE + Assignment pairing

class CloudIDEIntegration < ApplicationRecord
  belongs_to :cloud_ide
end
