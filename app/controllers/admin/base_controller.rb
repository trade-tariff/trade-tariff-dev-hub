class Admin::BaseController < AuthenticatedController
private

  def allowed_roles
    %w[admin]
  end
end
