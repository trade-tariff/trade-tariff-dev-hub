module UserVerification
  module Steps
    class Details < WizardSteps::Step
      def initialize(wizard, store, attributes = {}, *args)
        super
        assign_attributes additional_attributes
      end

      attribute :organisation_name, :string
      attribute :eori_number, :string
      attribute :ukacs_reference, :string
      attribute :email_address, :string
      attribute :application_reference, :string

      validates :organisation_name, presence: true
      validates :ukacs_reference, presence: true
      validates :email_address, presence: true
      validates :eori_number, presence: true

      validate :validate_eori_number

      def validate_eori_number
        valid = CheckEoriNumber.new.call(eori_number)

        errors.add(:eori_number, :invalid) unless valid
      end

      def additional_attributes
        return {} if email_address.present?

        { email_address: @wizard.email_address }
      end
    end
  end
end
