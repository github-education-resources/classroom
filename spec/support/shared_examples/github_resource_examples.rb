shared_examples_for 'a GitHubResource descendant with attributes' do
  subject { described_class.new(id: 1, access_token: '1234') }

  it 'responds true to all attribute created methods' do
    subject.github_attributes.each do |github_attribute|
      expect(subject).to respond_to(github_attribute.to_sym)
    end
  end
end
