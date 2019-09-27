# frozen_string_literal: true

require "rails_helper"

RSpec.describe RosterEntry::ShowView do
  let(:roster_entry) { create(:roster_entry) }

  subject { RosterEntry::ShowView.new(roster_entry: roster_entry) }

  describe "#linked", :vcr do
    context "has a user" do
      before do
        roster_entry.user = classroom_student
        roster_entry.save
      end

      it "returns true" do
        expect(subject.linked?).to be_truthy
      end
    end

    context "does not have a user" do
      before do
        roster_entry.user = nil
        roster_entry.save
      end

      it "returns false" do
        expect(subject.linked?).to be_falsey
      end
    end
  end

  describe "#github_handle_text", :vcr do
    context "when linked" do
      before do
        roster_entry.user = classroom_student
        roster_entry.save
      end

      it "returns the handle prefaced by an @" do
        expect(subject.github_handle_text).to eq("@#{classroom_student.github_user.login}")
      end
    end

    context "when not linked" do
      before do
        roster_entry.user = nil
        roster_entry.save
      end

      it 'returns "Not linked"' do
        expect(subject.github_handle_text).to eq("Not linked")
      end
    end
  end

  describe "#button_text", :vcr do
    context "when linked" do
      before do
        roster_entry.user = classroom_student
        roster_entry.save
      end

      it "returns unlink text" do
        expect(subject.button_text).to eq("Unlink GitHub account")
      end
    end

    context "when not linked" do
      before do
        roster_entry.user = nil
        roster_entry.save
      end

      it "returns link text" do
        expect(subject.button_text).to eq("Link GitHub account")
      end
    end
  end

  describe "#button_class", :vcr do
    context "when linked" do
      before do
        roster_entry.user = classroom_student
        roster_entry.save
      end

      it "returns danger button class" do
        expect(subject.button_class).to eq("btn btn-danger")
      end
    end

    context "when not linked" do
      before do
        roster_entry.user = nil
        roster_entry.save
      end

      it "returns outline button class" do
        expect(subject.button_class).to eq("btn btn-outline")
      end
    end
  end
end
