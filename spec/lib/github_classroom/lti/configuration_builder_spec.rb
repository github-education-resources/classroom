# frozen_string_literal: true

require "rails_helper"

describe GitHubClassroom::LTI::ConfigurationBuilder do
  subject { described_class }

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

  it "Generates a bare minimum xml configuration" do
    expected = IMS::LTI::Services::ToolConfig.new(title: title, launch_url: launch_url).to_xml
    actual = subject.build_xml(title, launch_url)

    expect(actual).to eq(expected)
  end

  it "Generates an xml configuration with options" do
    config_hash = options.merge(title: title, launch_url: launch_url)
    expected = IMS::LTI::Services::ToolConfig.new(config_hash).to_xml

    actual = subject.build_xml(title, launch_url, options)

    expect(actual).to eq(expected)
  end
end
