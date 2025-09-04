class HomepageController < ApplicationController
  def index
    redirect_to placeholder_users_path
  end
end
