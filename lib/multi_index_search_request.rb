# frozen_string_literal: true

# This class allows us to get around the single index search constraint in Chewy
class MultiIndexSearchRequest < Chewy::Search::Request
  # By including this we get Kaminari pagination behavior
  include Chewy::Search::Pagination::Kaminari
end
