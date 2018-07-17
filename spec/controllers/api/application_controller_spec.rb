# frozen_string_literal: true

require "rails_helper"

RSpec.describe API::ApplicationController, type: :controller do
  controller do
    def index
      render body: nil, status: :ok
    end
  end

  describe "API Application Controller Authentication Tests" do
    context "user has adequate scopes" do
      subject { classroom_teacher }

      context "user is logged in" do
        before(:each) do
          sign_in_as(subject)
        end

        context "user access token is valid" do
          it "renders action" do
            get :index
            expect(response.status).to eq(:success)
          end
        end
  
        context "user access token is invalid" do
          before do
            User.any_instance.stub(:authorized_access_token?).and_return(false)
          end

          it "returns forbidden" do
            get :index
            expect(response.status).to eq(:forbidden)
          end
        end
      end
  
      context "user is not logged in" do
        it "returns forbidden" do
          get :index
          expect(response.status).to eq(:forbidden)
        end
      end
    end

    context "user does not have adequate scopes" do
      subject { classroom_student }
      
      it "returns forbidden" do
        expect(response.status).to eq(:forbidden)
      end
      
    end
  end
end