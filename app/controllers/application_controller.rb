class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  def set_organisation_id
    params[:organisation_id] ||= ENV['ORGANISATION_ID']
  end
end
