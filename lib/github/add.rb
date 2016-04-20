# frozen_string_literal: true
module GitHub
  class Add
    attr_accessor :add_client

    def initialize(access_token)
      @add_client = Octokit::Client.new(access_token: access_token)
    end

    def add_email(email_address)
      @add_client.add_email(email_address)
    end

  end
end
