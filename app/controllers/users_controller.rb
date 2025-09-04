class UsersController < ApplicationController
  before_action :authenticate!, only: %i[placeholder]

  def new; end
  def placeholder; end

private

  def authenticate!
    if current_user.nil?
      redirect_to(
        TradeTariffDevHub.identity_consumer_url,
        allow_other_host: true,
      )
    end
  end

  def current_user
    @current_user ||= begin
      token = cookies[:id_token]
      decoded_token = VerifyToken.new(token).call
      User.from_passwordless_payload!(payload) if decoded_token
    end
  end
end
