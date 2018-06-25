module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      puts "Hello there, are you who you say you are?"
      # call auth logic
      binding.pry
    end

    protected

    def find_verified_user
      # add auth logic
      fail 'User needs to be authenticated.'
    end
  end
end
