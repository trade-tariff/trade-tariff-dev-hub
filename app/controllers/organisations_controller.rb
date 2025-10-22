class OrganisationsController < AuthenticatedController
  def index; end

  def show
    @organisation = organisation
    @users = @organisation.users
    @invitations = @organisation.invitations.reject(&:accepted?)
  end

  def edit
    @organisation = organisation
  end

  def update
    if organisation.update(organisation_params)
      redirect_to organisation_path(organisation), notice: "Organisation updated"
    else
      render :edit
    end
  end

private

  def allowed?
    current_user.organisation == organisation || current_user.admin?
  end

  def disallowed_redirect!
    redirect_to organisation_path(current_user.organisation)
  end

  def organisation
    @organisation ||= Organisation.find_by(id: params[:id])
  end

  def organisation_params
    params.require(:organisation).permit(:organisation_name)
  end
end
