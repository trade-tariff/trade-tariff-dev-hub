# frozen_string_literal: true

module RecordOwnershipAuthorization
  extend ActiveSupport::Concern

private

  def find_owned_record(model_class, id: params[:id])
    if organisation&.admin?
      model_class.find_by(id: id)
    else
      model_class.find_by(id: id, organisation_id: organisation_id)
    end
  end

  def redirect_path_for_owned_record(record, default_path:)
    if organisation&.admin? && record && record.organisation_id != organisation.id
      admin_organisation_path(record.organisation_id)
    else
      default_path
    end
  end
end
