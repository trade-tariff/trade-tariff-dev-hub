class Organisation < ApplicationRecord
  has_paper_trail

  enum :status, {
    unregistered: 0,
    authorised: 1,
    pending: 2,
    rejected: 3,
  }
end
