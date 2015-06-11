class AssignmentsController < ApplicationController
  before_action :set_assignment, except: [:new, :create]
  before_action :set_organization, only: [:new, :create]

  def show
  end

  def new
    @assignment = Assignment.new
  end

  def create
    @assignment = Assignment.new(new_assignment_params)

    if @assignment.save
      CreateAssignmentInvitationJob.perform_later(@assignment)

      flash[:success] = "\"#{@assignment.title}\" has been created!"
      redirect_to organization_assignment_path(@organization, @assignment)
    else
      render :new
    end
  end

  private

  def new_assignment_params
    params
      .require(:assignment)
      .permit(:title)
      .merge(organization_id: params[:organization_id])
  end

  def set_assignment
    @assignment = Assignment.find(params[:id])
  end

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end
end
