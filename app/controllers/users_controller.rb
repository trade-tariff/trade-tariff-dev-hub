class UsersController < ApplicationController
  before_action :authenticate!, only: %i[placeholder]

  def new; end

  def placeholder
    cognito_secret_struct = Struct.new(:client_id, :client_secret, :client_name, keyword_init: true)

    @client_secrets = 3.times.map do |i|
      cognito_secret_struct.new(
        client_id: SecureRandom.uuid,
        client_secret: SecureRandom.base64(32),
        client_name: "Client #{Faker::App.name} #{i + 1}",
      )
    end
  end

private

  def authenticate!
    Rails.logger.debug("Authenticating user...")
    if current_user.nil?
      Rails.logger.debug("No user found, redirecting to identity provider... #{TradeTariffDevHub.identity_consumer_url}")
      redirect_to(
        TradeTariffDevHub.identity_consumer_url,
        allow_other_host: true,
      )
    end
  end

  def current_user
    @current_user ||= begin
      Rails.logger.debug("Finding current user from token...")
      token = cookies[:id_token]
      Rails.logger.debug("Token found: #{token}")
      decoded_token = VerifyToken.new(token).call
      Rails.logger.debug("Decoded token: #{decoded_token}")

      Rails.logger.debug("Finding or creating user from token payload...")
      User.from_passwordless_payload!(decoded_token) if decoded_token
      Rails.logger.debug("Current user set: #{@current_user.inspect}")
    end
  end
end
