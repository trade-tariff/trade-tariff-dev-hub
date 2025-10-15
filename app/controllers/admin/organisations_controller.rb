class Admin::OrganisationsController < AuthenticatedController
  include Pagy::Backend

  before_action :ensure_admin

  def index
    @sort_column = params[:sort].presence || "created_at"
    @sort_direction = params[:direction].presence || "desc"

    # Validate sort column
    @sort_column = "created_at" unless %w[name created_at].include?(@sort_column)
    @sort_direction = "desc" unless %w[asc desc].include?(@sort_direction)

    # Map 'name' to 'organisation_name' for the database column
    db_column = @sort_column == "name" ? "organisation_name" : @sort_column

    @pagy, @organisations = pagy(
      Organisation.includes(:users, :api_keys, :ott_keys, :invitations)
                  .order(db_column => @sort_direction.to_sym),
      page: params[:page],
      items: 20,
    )
  end

  def show
    @organisation = Organisation
                     .includes(:roles, :users, :api_keys, :ott_keys, :invitations)
                     .find(params[:id])
    @roles = @organisation.roles.sort_by(&:name)
    @admin_role = @roles.find(&:admin?)
    @service_roles = @roles.reject(&:admin?)
    assigned_service_role_ids = @service_roles.map(&:id)
    @available_role_options = Role.service_roles
                                  .where.not(id: assigned_service_role_ids)
                                  .order(:name)
    @users = @organisation.users
    @api_keys = @organisation.api_keys
    @ott_keys = @organisation.ott_keys
    @invitations = @organisation.invitations.reject(&:accepted?)
  end

private

  def ensure_admin
    redirect_to root_path, alert: "Access denied" unless organisation.admin?
  end

  def allowed?
    # Override to check for admin role
    organisation.admin?
  end

  def allowed_roles
    # Empty to allow any role, we check admin in allowed?
    %w[admin]
  end
end
