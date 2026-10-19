class User < ApplicationRecord
  has_many :passkeys, dependent: :destroy
  has_many :todos, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :webauthn_id, presence: true, uniqueness: true
end
