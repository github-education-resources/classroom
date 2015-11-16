require 'rails_helper'

RSpec.describe Stafftools::UsersController, type: :controller do
  let(:user)    { GitHubFactory.create_owner_classroom_org.users.first }
  let(:student) { GitHubFactory.create_classroom_student               }

  before(:each) do
    sign_in(user)
  end

  describe 'GET #index', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect { get :index }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
      end

      before(:each) do
        get :index
      end

      it 'returns a success status' do
        expect(response).to have_http_status(:success)
      end

      it 'as an array of users' do
        expect(assigns(:users)).to_not be_nil

        expect(assigns(:users)).to respond_to(:total_count)
        expect(assigns(:users)).to be_kind_of(UsersIndex::User::Query)
      end

      it 'renders the user_results partial' do
        expect(response).to render_template(partial: 'stafftools/users/_users')
      end
    end
  end

  describe 'POST #impersonate_user', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect { post :impersonate, id: student.id }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
      end

      before(:each) do
        post :impersonate, id: student.id
      end

      it 'sets the :impersonated_user_id on the session' do
        expect(session[:impersonated_user_id]).to eql(student.id)
      end

      it 'redirects to the root_path' do
        expect(response).to redirect_to('/')
      end
    end
  end

  describe 'POST #stop_impersonating', :vcr do
    context 'as an unauthorized user' do
      it 'returns a 404' do
        expect { post :stop_impersonating, id: student.id }.to raise_error(ActionController::RoutingError)
      end
    end

    context 'as an authorized user' do
      before do
        user.update_attributes(site_admin: true)
      end

      before(:each) do
        post :stop_impersonating
      end

      it 'removes the `:impersonated_user_id` from the session' do
        expect(session[:impersonated_user_id]).to be_nil
      end

      it 'redirects back to the `stafftools_root_path`' do
        expect(response).to redirect_to('/stafftools')
      end
    end
  end
end
