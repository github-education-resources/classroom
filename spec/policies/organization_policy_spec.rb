require 'rails_helper'

describe OrganizationPolicy do
  let(:user) { create(:user_with_organizations) }

  subject { described_class }

  permissions :index? do
    it 'will never allow index' do
    end
  end

  permissions :new? do
    it 'will allow the creation of a new organization' do
    end
  end

  permissions :create? do
    it '' do
    end
  end

  permissions :show? do
    it '' do
    end
  end

  permissions :edit? do
    it '' do
    end
  end

  permissions :update? do
    it '' do
    end
  end

  permissions :destroy? do
    it '' do
    end
  end

  permissions :new_assignment? do
    it '' do
    end
  end
end
