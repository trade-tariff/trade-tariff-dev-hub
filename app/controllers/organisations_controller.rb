class OrganisationsController < AuthenticatedController
  def index
    redirect_to organisation_path(current_user.organisation)
  end

  def show
    @organisation = Organisation.includes(:users, :invitations, :api_keys, :trade_tariff_keys, :roles, role_requests: []).find(organisation.id)
    @users = @organisation.users
    @invitations = @organisation.invitations.reject(&:accepted?)
    @api_keys = @organisation.api_keys if @organisation.has_role?("fpo:full")
    @trade_tariff_keys = @organisation.trade_tariff_keys if @organisation.has_role?("trade_tariff:full")
    @service_roles = @organisation.roles.service_roles.order(:name)
    @available_roles = @organisation.available_service_roles
    @has_available_roles = @available_roles.any? && !@organisation.admin?

    # Preload pending requests to avoid N+1 queries in view
    if @has_available_roles
      @pending_role_names = @organisation.role_requests.pending.pluck(:role_name).to_set
      @available_without_pending = @available_roles.reject { |role| @pending_role_names.include?(role.name) }
      @pending_roles = @available_roles.select { |role| @pending_role_names.include?(role.name) }
    end
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
    @organisation ||= Organisation.find_by(id: params[:id]) || current_user.organisation
  end

  def organisation_params
    params.require(:organisation).permit(:organisation_name)
  end
end
