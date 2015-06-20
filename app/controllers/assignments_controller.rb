class AssignmentsController < OrganizationAuthorizedController
  before_action :set_assignment, except: [:new, :create]

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

  def show
  end

  private

  def new_assignment_params
    params
      .require(:assignment)
      .permit(:title, :public_repo)
      .merge(organization_id: params[:organization_id])
  end

  def set_assignment
    @assignment = Assignment.find(params[:id])
  end
end
