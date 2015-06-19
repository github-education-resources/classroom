require 'rails_helper'

RSpec.describe UsersController, type: :controller do
  before(:each) do
    session[:user_id] = create(:user).id
  end

  describe 'GET #show' do
    it 'returns success and sets the user' do
      get :show

      expect(response).to have_http_status(:success)
      expect(assigns(:user)).to_not be_nil
    end
  end
end
