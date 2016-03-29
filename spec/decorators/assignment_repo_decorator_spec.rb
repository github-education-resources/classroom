require 'rails_helper'

RSpec.describe AssignmentRepoDecorator do
  let(:user) { User.new }
  let(:assignment_repo) do
    AssignmentRepo.new.tap do |repo|
      repo.user = user
    end
  end

  subject { assignment_repo.decorate }

  describe '#avatar_url' do
    before do
      allow(user).to receive(:uid).and_return('an_uid')
    end

    it 'fetches the avatar url in given size' do
      expect(subject.avatar_url(100)).to eq('https://avatars.githubusercontent.com/u/an_uid?v=3&size=100')
    end
  end

  describe '#full_name' do
    let(:github_repository) { double('repository', full_name: 'repo_name') }

    before do
      allow(subject)
        .to receive(:github_repository).and_return(github_repository)
    end

    it 'delegated to repository full_name' do
      expect(subject.full_name).to eq('repo_name')
    end
  end

  describe '#github_url' do
    let(:github_repository) { double('repository', html_url: 'repo_url') }

    before do
      allow(subject).to receive(:github_repository).and_return(github_repository)
    end

    it 'delegated to repository html_url' do
      expect(subject.github_url).to eq('repo_url')
    end
  end

  describe '#disabled?' do
    before do
      allow(subject).to receive(:github_repository).and_return(github_repository)
      allow(subject).to receive(:student).and_return(student)
    end

    context 'when github_repository is Null-Object' do
      let(:github_repository) { NullGitHubRepository.new }
      let(:student) { NullGitHubUser.new }

      it 'it should be truthy' do
        expect(subject.disabled?).to be_truthy
      end
    end

    context 'when github_repository is Null-Object' do
      let(:github_repository) { double('repository', null?: false) }
      let(:student) { NullGitHubUser.new }

      it 'should be truthy' do
        expect(subject.disabled?).to be_truthy
      end
    end

    context 'when repo and user present' do
      let(:github_repository) { double('repository', null?: false) }
      let(:student) { double('student', null?: false) }

      it 'should be falsey' do
        expect(subject.disabled?).to be_falsey
      end
    end
  end

  describe '#student_login' do
    let(:login) { double('login') }
    let(:student) { double('student', login: login) }

    before do
      allow(subject).to receive(:student).and_return(student)
    end

    it 'delegates student_login to student' do
      expect(subject.student_login).to eq(login)
    end
  end

  describe '#student_name' do
    let(:name) { double('name') }
    let(:student) { double('student', name: name) }

    before do
      allow(subject).to receive(:student).and_return(student)
    end

    it 'delegates student_name to student' do
      expect(subject.student_name).to eq(name)
    end
  end
end
