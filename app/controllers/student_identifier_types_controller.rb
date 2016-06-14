# frozen_string_literal: true
class StudentIdentifierTypesController < ApplicationController
  include OrganizationAuthorization

  def index
    @student_identifier_types = @organization.student_identifier_types
  end

  def new
    @student_identifier_type = StudentIdentifierType.new
  end

  def create
    @student_identifier_type = StudentIdentifierType.new(new_student_identifier_type_params)
    if @student_identifier_type.save
      flash[:success] = "\"#{student_identifier_type.name}\" has been created!"
      redirect_to action: 'index'
    else
      render :new
    end
  end

  def destroy
    student_identifier_type = StudentIdentifierType.find_by(id: params[:id])
    if student_identifier_type.update_attributes(deleted_at: Time.zone.now)
      DestroyResourceJob.perform_later(student_identifier_type)
      flash[:success] = "\"#{student_identifier_type.name}\" is being deleted"
    end
    redirect_to action: 'index'
  end

  def new_student_identifier_type_params
    params
      .require(:student_identifier_type)
      .permit(:name, :description, :content_type)
      .merge(organization: @organization)
  end

  private

  def student_identifier_type
    @student_identifier_type ||= StudentIdentifierType.find_by(id: params[:id])
  end
  helper_method :student_identifier_type
end
