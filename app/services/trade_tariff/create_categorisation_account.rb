# frozen_string_literal: true

class TradeTariff::CreateCategorisationAccount
  Result = Data.define(:user, :categorisation_key, :client_secret)

  def initialize(key_creator: nil)
    @key_creator = key_creator || TradeTariff::CreateCategorisationKey.new
  end

  def call(email_address, organisation_name)
    email_address = normalize_email(email_address)
    validate_email!(email_address)

    existing_user = find_existing_user(email_address)
    return build_result(existing_user, @key_creator.call(existing_user.organisation)) if existing_user

    organisation_name = organisation_name.to_s.strip
    validate_organisation_name!(organisation_name)

    User.transaction do
      organisation = create_organisation!(organisation_name, email_address)
      user = create_user!(email_address, organisation)
      build_result(user, @key_creator.call(organisation))
    end
  end

private

  def normalize_email(email_address)
    email_address.to_s.strip.downcase
  end

  def validate_email!(email_address)
    return if email_address.match?(URI::MailTo::EMAIL_REGEXP)

    raise ArgumentError, "A valid email address is required"
  end

  def validate_organisation_name!(organisation_name)
    raise ArgumentError, "Organisation name is required" if organisation_name.blank?
  end

  def find_existing_user(email_address)
    User.where("LOWER(email_address) = ?", email_address).first
  end

  def build_result(user, key_result)
    Result.new(
      user: user,
      categorisation_key: key_result.trade_tariff_key,
      client_secret: key_result.client_secret,
    )
  end

  def create_organisation!(organisation_name, email_address)
    Organisation.create!(
      organisation_name: organisation_name,
      description: "Categorisation API organisation for #{email_address}",
    ).tap do |organisation|
      organisation.assign_role!(Role::TRADE_TARIFF_ROLE_NAME)
    end
  end

  def create_user!(email_address, organisation)
    User.create!(
      email_address: email_address,
      organisation: organisation,
      user_id: "preprovisioned-#{SecureRandom.uuid}",
    )
  end
end
