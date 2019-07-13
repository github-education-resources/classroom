# frozen_string_literal: true

require "rails_helper"

describe GitHubClassroom::LTI::ConfigurationBuilder do
  let(:title) { Faker::App.name }
  let(:launch_url) { "www.example.com" }
  let(:options) do
    {
      description: Faker::Lorem.sentence,
      icon: "www.example.com/icon",
      vendor_code: Faker::Code.isbn,
      vendor_name: Faker::Company.name,
      vendor_description: Faker::Lorem.sentence,
      vendor_url: "www.vendor.com",
      vendor_contact_email: "vendor@example.com",
      vendor_contact_name: Faker::App.author
    }
  end

  let(:ext_vendor) { Faker::Company.name }
  let(:ext_options) do
    {
      param: Faker::Lorem.word,
      nested: {
        other_param: Faker::Lorem.sentence
      }
    }
  end
  subject { described_class.new(title, launch_url) }

  it "Generates a bare minimum xml configuration" do
    expected = IMS::LTI::Services::ToolConfig.new(title: title, launch_url: launch_url).to_xml
    actual = subject.to_xml

    expect(actual).to eq(expected)
  end

  it "Generates an xml configuration with global options" do
    config_hash = options.merge(title: title, launch_url: launch_url)
    expected = IMS::LTI::Services::ToolConfig.new(config_hash).to_xml

    actual = subject.add_attributes(options).to_xml

    expect(actual).to eq(expected)
  end

  it "Generates an xml configuration with vendor-specifc options" do
    config_hash = options.merge(title: title, launch_url: launch_url)
    config = IMS::LTI::Services::ToolConfig.new(config_hash)
    ext_options.each_pair do |k, v|
      config.set_ext_param(ext_vendor, k, v)
    end

    expected = config.to_xml
    actual = subject
      .add_attributes(options)
      .add_vendor_attributes(ext_vendor, ext_options)
      .to_xml

    expect(actual).to eq(expected)
  end
end
