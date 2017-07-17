# frozen_string_literal: true

shared_examples_for "a default scope where deleted_at is not present" do
  it "has the same SQL query" do
    expect(described_class.all.to_sql).to eq described_class.unscoped.all.where(deleted_at: nil).to_sql
  end
end
