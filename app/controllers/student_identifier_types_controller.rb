# frozen_string_literal: true
class StudentIdentifierTypesController < ApplicationController
  include OrganizationAuthorization

  decorates_assigned :organization
  decorates_assigned :student_identifier_type

  def index
    @student_identifier_types = @organization.student_identifier_types
  end

  def new
    @student_identifier_type = StudentIdentifierType.new
  end

  def create
    @student_identifier_type = StudentIdentifierType.new(new_student_identifier_type_params)
    if @student_identifier_type.save
      flash[:success] = "\"#{@student_identifier_type.name}\" has been created!"
      redirect_to action: "index"
    else
      render :new
    end
  end

  def destroy
    flash[:success] = "Identifier type deleted"
    redirect_to action: "index"
  end

  def new_student_identifier_type_params
    params
      .require(:student_identifier_type)
      .permit(:name, :description, :content_type)
      .merge(organization: @organization)
  end

end