class ApplicationController < ActionController::Base
  allow_browser versions: :modern

  def set_organisation_id
    params[:organisation_id] ||= ENV['ORGANISATION_ID']
  end

  def set_api_key_id
    @api_key ||= ApiKey.find(params[:id])
  end
end
