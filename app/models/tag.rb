# タスクに自由に複数付けられるラベル。カテゴリと違い階層やデフォルトはなく、
# 横断的な絞り込みに使う（TaskBoard の絞り込みチップを参照）。
class Tag < ApplicationRecord
  belongs_to :user
  has_many :taggings, dependent: :destroy
  has_many :tasks, through: :taggings

  validates :name, presence: { message: "名前を入れてや" },
            uniqueness: { scope: :user_id, message: "そのタグはもうあるで" }

  scope :ordered, -> { order(:name) }
end
