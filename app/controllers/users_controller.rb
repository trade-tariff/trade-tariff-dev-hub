class UsersController < AuthenticatedController
  include RecordOwnershipAuthorization

  def remove; end

  def destroy
    redirect_path = redirect_path_after_action

    if user.destroy
      redirect_to redirect_path, notice: "User #{user.email_address} has been removed from the organisation."
    else
      redirect_to redirect_path, alert: "There was a problem removing the user #{user.email_address} from the organisation."
    end
  end

private

  def allowed?
    return false if user.nil? || user == current_user

    current_user.organisation.users.include?(user) || current_user.admin?
  end

  def disallowed_redirect!
    redirect_path = redirect_path_after_action

    if user == current_user
      redirect_to redirect_path, alert: "You cannot delete your own user account"
    else
      redirect_to redirect_path, alert: "You can only delete users from your own organisation."
    end
  end

  def redirect_path_after_action
    redirect_path_for_owned_record(user, default_path: organisation_path(organisation.id))
  end

  def user
    @user ||= find_owned_record(User)
  end
end
