# やること1件。parent_id でどこまでも深くサブタスクに分割できる。
#
# 「すぐ終わる todo」「大きなタスク」といった分類はカラムに持たず、
# 子の有無と見積もり（ポモドーロ数）から導出する（クライアント側の
# TaskTree#kind_of を参照）。todo に子を足せば、それだけで大きなタスクになる。
class Task < ApplicationRecord
  POMODORO_MINUTES = 30
  # これ以下のポモドーロ数で終わる葉タスクを「すぐ終わる todo」とみなす
  QUICK_POMODOROS = 2

  belongs_to :user
  belongs_to :parent, class_name: "Task", optional: true, inverse_of: :children
  has_many :children, -> { order(:position, :id) },
           class_name: "Task", foreign_key: :parent_id,
           inverse_of: :parent, dependent: :destroy

  validates :title, presence: { message: "タイトルを入れてや" }
  validates :estimate_pomodoros,
            numericality: { only_integer: true, greater_than: 0, message: "見積もりは1以上の整数にしてや" },
            allow_nil: true
  validate :due_on_not_before_starts_on
  validate :parent_owned_by_same_user
  validate :parent_not_self_or_descendant

  before_save :append_to_siblings, if: -> { new_record? || will_save_change_to_parent_id? }

  scope :roots, -> { where(parent_id: nil) }
  scope :ordered, -> { order(:position, :id) }

  def done
    completed_at.present?
  end
  alias_method :done?, :done

  # チェックボックスから true/false で受け取れるようにする
  def done=(value)
    if ActiveModel::Type::Boolean.new.cast(value)
      self.completed_at ||= Time.current
    else
      self.completed_at = nil
    end
  end

  # 祖先を親から順に返す（ルートが最後）
  def ancestors
    result = []
    node = parent
    seen = Set.new
    while node && seen.add?(node.id)
      result << node
      node = node.parent
    end
    result
  end

  private

  def due_on_not_before_starts_on
    return unless starts_on && due_on
    errors.add(:due_on, "期限が開始日より前になってるで") if due_on < starts_on
  end

  def parent_owned_by_same_user
    return unless parent
    errors.add(:parent, "親タスクが見つからんで") if parent.user_id != user_id
  end

  def parent_not_self_or_descendant
    return unless parent && persisted?
    if parent.id == id || parent.ancestors.any? { |a| a.id == id }
      errors.add(:parent, "自分自身やサブタスクの下には移動できへんで")
    end
  end

  # 新規作成時や親を付け替えた時は、兄弟の末尾に並べる
  def append_to_siblings
    return if position_changed? && position.to_i.positive?
    max = Task.where(user_id: user_id, parent_id: parent_id).where.not(id: id).maximum(:position)
    self.position = max.to_i + 1
  end
end
