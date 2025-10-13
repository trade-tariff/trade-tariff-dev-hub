class UsersController < AuthenticatedController
  def remove; end

  def destroy
    if user.destroy
      redirect_to organisation_path(organisation.id), notice: "User #{user.email_address} has been removed from the organisation."
    else
      redirect_to organisation_path(organisation.id), alert: "There was a problem removing the user #{user.email_address} from the organisation."
    end
  end

private

  def allowed?
    user != current_user &&
      current_user.organisation.users.include?(user)
  end

  def disallowed_redirect!
    if user == current_user
      redirect_to organisation_path(organisation.id), alert: "You cannot delete your own user account"
    else
      redirect_to organisation_path(organisation.id), alert: "You can only delete users from your own organisation."
    end
  end

  def user
    @user ||= User.find_by(id: params[:id])
  end
end
