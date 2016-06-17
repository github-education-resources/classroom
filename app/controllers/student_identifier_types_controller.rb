# frozen_string_literal: true
class StudentIdentifierTypesController < ApplicationController
  include OrganizationAuthorization

  before_action :set_student_identifier_type, only: [:edit, :update]
  before_action :save_referer, only: [:new]

  def index
    @student_identifier_types = @organization.student_identifier_types
  end

  def new
    @student_identifier_type = StudentIdentifierType.new
  end

  def edit
  end

  def create
    @student_identifier_type = StudentIdentifierType.new(student_identifier_type_params)
    if @student_identifier_type.save
      flash[:success] = "\"#{student_identifier_type.name}\" has been created!"
      redirect_to session.delete(:return_to) || { action: 'index' }
    else
      render :new
    end
  end

  def update
    @student_identifier_type.update_attributes(student_identifier_type_params)
    if @student_identifier_type.save
      flash[:success] = "\"#{student_identifier_type.name}\" has been updated!"
      redirect_to action: 'index'
    else
      render :edit
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

  def student_identifier_type_params
    params
      .require(:student_identifier_type)
      .permit(:name, :description, :content_type)
      .merge(organization: @organization)
  end

  private

  def set_student_identifier_type
    @student_identifier_type = StudentIdentifierType.find_by(id: params[:id])
  end

  def save_referer
    session[:return_to] = request.referer
  end

  def student_identifier_type
    @student_identifier_type ||= StudentIdentifierType.find_by(id: params[:id])
  end
  helper_method :student_identifier_type
end
