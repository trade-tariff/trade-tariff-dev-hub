class Admin::OrganisationsController < Admin::BaseController
  include Pagy::Backend

  def index
    @search_query = params[:q].to_s.strip

    @sort_column = params[:sort].presence || "created_at"
    @sort_direction = params[:direction].presence || "desc"

    # Validate sort column
    @sort_column = "created_at" unless %w[name created_at].include?(@sort_column)
    @sort_direction = "desc" unless %w[asc desc].include?(@sort_direction)

    # Map 'name' to 'organisation_name' for the database column
    db_column = @sort_column == "name" ? "organisation_name" : @sort_column

    scope = Organisation.includes(:users, :api_keys, :trade_tariff_keys, :invitations, :roles)
    scope = scope.matching_name(@search_query) if @search_query.present?
    scope = scope.order(db_column => @sort_direction.to_sym)

    @pagy, @organisations = pagy(
      scope,
      page: params[:page],
      limit: TradeTariffDevHub::ADMIN_PAGY_PAGE_SIZE,
      params: pagy_index_params,
    )
  end

  def show
    @organisation = Organisation
                     .includes(:roles, :users, :api_keys, :trade_tariff_keys, :invitations)
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
    @trade_tariff_keys = @organisation.trade_tariff_keys
    @invitations = @organisation.invitations.reject(&:accepted?)
  end

private

  def pagy_index_params
    {
      q: @search_query.presence,
      sort: params[:sort].presence_in(%w[name created_at]),
      direction: params[:direction].presence_in(%w[asc desc]),
    }.compact
  end
end
