class OrganisationsController < AuthenticatedController
  def index
    unless current_user.admin?
      redirect_to organisation_path(organisation)
    end
  end

  def show
    if correct_path_for_non_admin_user? || current_user.admin?
      @organisation = organisation
      @users = @organisation.users
      @invitations = @organisation.invitations
    else
      redirect_to organisation_path(organisation)
    end
  end

  def edit
    @organisation = organisation
  end

  def update
    @organisation = organisation

    if @organisation.update(organisation_params)
      redirect_to organisation_path(@organisation), notice: "Organisation updated"
    else
      render :edit
    end
  end

private

  def allowed?
    current_user.organisation == organisation || current_user.admin?
  end

  def organisation
    @organisation ||= if current_user.admin?
                        Organisation.find_by(id: params[:id])
                      else
                        super
                      end
  end

  def organisation_params
    params.require(:organisation).permit(:organisation_name)
  end

  def correct_path_for_non_admin_user?
    expected_path = organisation_path(organisation)

    request.path.include?(expected_path)
  end
end
