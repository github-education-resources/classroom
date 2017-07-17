# frozen_string_literal: true

require "rails_helper"

RSpec.describe ViewModel do
  it "takes an attributes hash" do
    view = ViewModel.new(foo: "bar")
    expect("bar").to eql(view.attributes[:foo])
  end

  it "gets an empty attributes hash by default" do
    expect({}).to eql(ViewModel.new.attributes)
    expect({}).to eql(ViewModel.new(nil).attributes)
  end

  class WithAttributes < ViewModel
    attr_reader :foo
  end

  class WithAttributesChild < WithAttributes
    attr_reader :baz
  end

  class WithMultipleAttributes < ViewModel
    attr_reader :foo, :baz
  end

  it "automatically sets ivars for ctor attributes if there's an attr_reader" do
    view = WithAttributes.new(foo: "bar", baz: :quux)
    expect("bar").to eql(view.foo)
    expect { view.baz }.to raise_error(NoMethodError)
  end

  it "ivar setting works for hierarchies too" do
    view = WithAttributesChild.new(foo: "bar", baz: :quux)

    expect("bar").to eql(view.foo)
    expect(:quux).to eql(view.baz)
  end

  it "attr_reader appropriately handles multiple names" do
    view = WithMultipleAttributes.new(foo: :bar, baz: :quux)

    expect(:bar).to eql(view.foo)
    expect(:quux).to eql(view.baz)
  end
end
