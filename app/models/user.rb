class User < ApplicationRecord
  has_many :passkeys, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :categories, dependent: :destroy
  has_many :tags, dependent: :destroy

  after_create :create_default_category

  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :webauthn_id, presence: true, uniqueness: true

  # タスクは必ずどこかのカテゴリに入る。選ばなかった／カテゴリを削除された
  # タスクの行き先として、ユーザーごとに常に1つ存在させる
  def default_category
    categories.find_by(is_default: true) || categories.create!(name: "default", is_default: true)
  end

  private

  def create_default_category
    categories.create!(name: "default", is_default: true)
  end
end
