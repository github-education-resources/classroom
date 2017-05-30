require 'rails_helper'

RSpec.describe API::SigninController, type: :controller do
  describe 'GET #index' do
    context 'unauthenticated request' do
      before do
        sign_out
      end

      it 'redirects to login path' do
        get :index
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
