class Admin::OrganisationsController < AuthenticatedController
  include Pagy::Backend

  before_action :ensure_admin

  def index
    @pagy, @organisations = pagy(
      Organisation.includes(:users, :api_keys, :ott_keys, :invitations)
                  .order(created_at: :desc),
      page: params[:page],
      items: 20,
    )
  end

  def show
    @organisation = Organisation.find(params[:id])
    @users = @organisation.users
    @api_keys = @organisation.api_keys
    @ott_keys = @organisation.ott_keys
    @invitations = @organisation.invitations
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
    []
  end
end
