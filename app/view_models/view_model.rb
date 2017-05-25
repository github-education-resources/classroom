# frozen_string_literal: true

# An optional superclass for view models. `ViewModel` provides a
# consistent hash-based attributes initializer.

class ViewModel
  # Public: Track each attr_reader added to ViewModel subclasses.
  def self.attr_reader(*names)
    attr_initializable(*names)
    super
  end

  def self.attr_initializable(*names)
    attr_initializables.concat(names.map(&:to_sym) - [:attributes])
  end

  # Internal: An Array of hash initializable attributes on this class.
  def self.attr_initializables
    @attr_initializables ||= (superclass <= ViewModel ? superclass.attr_initializables.dup : [])
  end

  # Internal: The attributes used to initialize this instance.
  attr_reader :attributes

  # Public: Create a new instance, optionally providing a `Hash` of
  # `attributes`. Any attributes with the same name as an
  # `attr_reader` will be set as instance variables.
  def initialize(attributes = nil)
    update(attributes || {})
    after_initialize if respond_to? :after_initialize
  end

  # Internal: Update this instance's attribute instance variables with
  # new values.
  #
  # attributes - A Symbol-keyed Hash of new attribute values.
  #
  # Returns self.
  def update(attributes)
    (@attributes ||= {}).merge! attributes

    (self.class.attr_initializables & attributes.keys).each do |name|
      instance_variable_set :"@#{name}", attributes[name]
    end

    self
  end
end
