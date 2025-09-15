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
    redirect_to TradeTariffDevHub.identity_consumer_url, allow_other_host: true if current_user.nil?
  end

  def current_user
    @current_user ||= begin
      token = cookies[:id_token]
      decoded_token = VerifyToken.new(token).call

      User.from_passwordless_payload!(decoded_token) if decoded_token
    end
  end
end
