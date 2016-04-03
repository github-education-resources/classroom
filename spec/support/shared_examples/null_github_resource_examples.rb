shared_examples_for 'a NullGitHubResource descendant with attributes' do
  subject { described_class.new }

  it 'responds true to all attribute created methods' do
    subject.null_github_attributes.each do |attribute, value|
      expect(subject).to respond_to(attribute)
      expect(subject.send(attribute)).to eql(value)
    end
  end
end
