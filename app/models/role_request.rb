# frozen_string_literal: true

# == Schema Information
#
# Table name: role_requests
#
#  id              :uuid             not null, primary key
#  organisation_id :uuid             not null
#  user_id         :uuid             not null
#  role_name       :string           not null
#  note            :text
#  status          :enum             default("pending"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_role_requests_on_org_role_status  (organisation_id,role_name,status)
#  index_role_requests_on_organisation_id  (organisation_id)
#  index_role_requests_on_user_id          (user_id)
#

class RoleRequest < ApplicationRecord
  has_paper_trail

  belongs_to :organisation
  belongs_to :user

  attribute :status, :string

  validates :role_name, presence: true
  validates :role_name, inclusion: { in: Role.assignable_names, message: "is not a valid assignable role" }
  validates :note, length: { maximum: 200, message: "must be 200 characters or fewer" }
  validate :organisation_does_not_have_role
  validate :no_duplicate_pending_request

  enum :status, {
    pending: "pending",
    approved: "approved",
    rejected: "rejected",
  }, default: "pending"

  scope :pending, -> { where(status: "pending") }

  def approve!(approved_by: nil)
    raise ArgumentError, "approve! must be called by an admin user" if approved_by.nil?
    raise ArgumentError, "approve! must be called by an admin user" unless approved_by.admin?

    transaction do
      update!(status: :approved)
      organisation.assign_role!(role_name)
      self
    end
  end

private

  def organisation_does_not_have_role
    return unless organisation.present? && role_name.present?

    if organisation.has_role?(role_name)
      errors.add(:role_name, "is already assigned to this organisation")
    end
  end

  def no_duplicate_pending_request
    return unless organisation.present? && role_name.present?

    existing = RoleRequest.where(
      organisation_id: organisation_id,
      role_name: role_name,
      status: :pending,
    ).where.not(id: id)

    if existing.exists?
      errors.add(:role_name, "has already been requested and is pending")
    end
  end
end
