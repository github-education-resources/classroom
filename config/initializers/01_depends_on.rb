# frozen_string_literal: true

class Module
  # Allows you to break big classes up into multiple files.
  #
  #   # app/controllers/application_controller.rb
  #   class ApplicationController < ActionController::Base
  #     # require_dependency 'application_controller/authentication_dependency'
  #     # require_dependency 'application_controller/errors_dependency'
  #     # require_dependency 'application_controller/feature_flags_dependency'
  #
  #     depends_on :authentication, :errors, :feature_flags
  #
  #   # app/controllers/application_controller/authetnication_dependency.rb
  #   class ApplicationController
  #   end
  #
  # Each dependency should reopen the class and do its thing.  No more mucking
  # with defining ClassMethods modules or messing with the self.included
  # callback.
  #
  # *files - Splatted array of String or Symbol filenames.  Each one will be
  #          expanded to "#{name.underscore}/#{file}_dependency"
  #
  # Returns nothing.
  def depends_on(*files)
    files.each do |file|
      require_dependency "#{name.underscore}/#{file}_dependency"
    end
  end
end
