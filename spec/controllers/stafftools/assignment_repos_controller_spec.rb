require 'rails_helper'

RSpec.describe Stafftools::AssignmentReposController, type: :controller do
  let(:user)    { GitHubFactory.create_owner_classroom_org.users.first }
  let(:student) { GitHubFactory.create_classroom_student               }

  let(:assignment) { create(:assignment, creator: user, organization: user.organizations.first, public_repo: false) }

  let(:assignment_repo) { AssignmentRepo.create(assignment: assignment, user: student) }

  before(:each) do
    sign_in(user)
  end

  after do
    AssignmentRepo.destroy_all
  end

  describe 'GET #show', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect { get :show, id: assignment_repo.id }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
        get :show, id: assignment_repo.id
      end

      it 'succeeds' do
        expect(response).to have_http_status(:success)
      end

      it 'sets the AssignmentRepo' do
        expect(assigns(:assignment_repo).id).to eq(assignment_repo.id)
      end
    end
  end
end
