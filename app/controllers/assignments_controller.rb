class AssignmentsController < ApplicationController
  before_action :set_organization
  before_action :set_assignment,  only: [:show, :edit, :update, :destroy]

  def new
    @assignment = Assignment.new
  end

  def create
    @assignment = Assignment.new(assignment_params)
    @assignment.organization = @organization

    if @assignment.save
      flash[:success] = "Your assignment \"#{@assignment.title}\" has been created!"
      redirect_to organization_assignment_path(@organization, @assignment)
    else
      render :new
    end
  end

  def show
  end

  def edit
  end

  def update
    if @assignment.update_attributes(assignment_params)
      flash[:success] = "Assignment \"#{}\" has been updated!"
      redirect_to organization_assignment_path(@organization, @assignment)
    else
      render :edit
    end
  end

  def destroy
    flash_message = "\"#{@assignment.title}\" has been deleted"

    if @assignment.destroy
      flash[:success] = flash_message
      redirect_to organization_path(@organization)
    end
  end

  private

  def assignment_params
    params.require(:assignment).permit(:title)
  end

  def set_assignment
    @assignment = Assignment.find(params[:id])
  end

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end
end
