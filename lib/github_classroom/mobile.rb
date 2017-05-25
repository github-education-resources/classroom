# frozen_string_literal: true

module GitHubClassroom
  module Mobile
    # Public: Does the user agent say that we're on a mobile device?
    #
    # user_agent - Browser user agent string to check for mobile.
    #
    # Returns a boolean.
    def self.mobile_user_agent?(user_agent)
      # iPhones, iPod Touches, Android phones, Firefox OS, and WP8 phones only for now
      user_agent =~ /iPhone;|iPod( touch)?;|Android.*Mobile|Mobile.*Firefox|IEMobile/
    end
  end
end
