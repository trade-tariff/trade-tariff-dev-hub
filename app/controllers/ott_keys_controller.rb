class OttKeysController < AuthenticatedController
  before_action :set_ott_key, only: %i[update revoke delete]

  def index
    @ott_keys = OttKey.where(organisation_id: organisation_id).order(created_at: :desc)
  end

  def new; end

  def update
    if @ott_key.enabled
      render "revoke"
    else
      render "delete"
    end
  end

  def create
    # For now, use default scopes - can be enhanced later
    default_scopes = %w[read write]
    @ott_key = Ott::CreateOttKey.new.call(organisation_id, params[:ott_key_description], default_scopes)
  end

  def revoke
    if @ott_key.blank?
      redirect_to redirect_path_after_action, alert: "OTT key not found"
    elsif @ott_key.revoked?
      redirect_to redirect_path_after_action, alert: "OTT key already revoked"
    else
      Ott::RevokeOttKey.new.call(@ott_key)
      redirect_to redirect_path_after_action, notice: "OTT key revoked"
    end
  end

  def delete
    Ott::DeleteOttKey.new.call(@ott_key)
    redirect_to redirect_path_after_action, notice: "OTT key deleted"
  end

private

  def set_ott_key
    @ott_key = if organisation&.admin?
                 # Admins can access any OTT key
                 OttKey.find_by(id: params[:id])
               else
                 # Regular users can only access their organisation's keys
                 OttKey.find_by(id: params[:id], organisation_id:)
               end

    unless @ott_key
      redirect_to redirect_path_after_action, alert: "OTT key not found"
      nil
    end
  end

  def redirect_path_after_action
    # If user is an admin and the OTT key belongs to a different organisation,
    # redirect to that organisation's admin page
    if organisation&.admin? && @ott_key && @ott_key.organisation_id != organisation.id
      admin_organisation_path(@ott_key.organisation_id)
    else
      ott_keys_path
    end
  end

  def allowed_roles
    %w[admin]
  end
end
