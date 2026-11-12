# タスクを分けるためのカテゴリ。ルートタスク作成時に割り当て、
# サブタスクは常に親と同じカテゴリを引き継ぐ（Task#assign_category）。
#
# is_default のカテゴリはユーザーごとに必ず1つあり（User#default_category）、
# カテゴリを選ばなかったタスクの行き先になる。タスクには必ずカテゴリが要るので
# （Task#category は必須）、is_default のカテゴリ自体は削除できない。
class Category < ApplicationRecord
  belongs_to :user
  has_many :tasks

  validates :name, presence: { message: "名前を入れてや" },
            uniqueness: { scope: :user_id, message: "そのカテゴリはもうあるで" }
  validates :is_default, uniqueness: { scope: :user_id, message: "既定カテゴリは1つだけやで" }, if: :is_default?

  before_validation :append_to_siblings, on: :create
  before_destroy :forbid_destroying_default
  before_destroy :move_tasks_to_default_category

  scope :ordered, -> { order(:position, :id) }

  private

  def append_to_siblings
    max = Category.where(user_id: user_id).maximum(:position)
    self.position = max.to_i + 1
  end

  def forbid_destroying_default
    return unless is_default?
    errors.add(:base, "既定カテゴリは削除できへん")
    throw :abort
  end

  def move_tasks_to_default_category
    tasks.update_all(category_id: user.default_category.id)
  end
end
