require "test_helper"

class TaskTest < ActiveSupport::TestCase
  setup do
    @user = create_user
  end

  test "タイトルは必須" do
    task = @user.tasks.new(title: "")
    assert_not task.valid?
    assert_includes task.errors.map(&:message), "タイトルを入れてや"
  end

  test "サブタスクはどこまでも深くできる" do
    root = @user.tasks.create!(title: "引っ越し")
    child = @user.tasks.create!(title: "荷造り", parent: root)
    grandchild = @user.tasks.create!(title: "本を箱に詰める", parent: child)

    assert_equal [ child, root ], grandchild.ancestors
    assert_equal [ child ], root.children.to_a
  end

  test "兄弟の末尾に並ぶ" do
    root = @user.tasks.create!(title: "親")
    a = @user.tasks.create!(title: "a", parent: root)
    b = @user.tasks.create!(title: "b", parent: root)
    assert_operator a.position, :<, b.position
  end

  test "親を付け替えると移動先の末尾に並ぶ" do
    p1 = @user.tasks.create!(title: "p1")
    p2 = @user.tasks.create!(title: "p2")
    existing = @user.tasks.create!(title: "x", parent: p2)
    moved = @user.tasks.create!(title: "y", parent: p1)

    moved.update!(parent: p2)
    assert_operator existing.position, :<, moved.reload.position
  end

  test "自分自身や子孫の下には移動できない" do
    root = @user.tasks.create!(title: "親")
    child = @user.tasks.create!(title: "子", parent: root)

    assert_not root.update(parent: child)
    assert_not root.update(parent: root)
  end

  test "他人のタスクの下には作れない" do
    other = create_user.tasks.create!(title: "他人の")
    task = @user.tasks.new(title: "私の", parent: other)
    assert_not task.valid?
  end

  test "開始日と期限はどちらも任意で、期限だけでもよい" do
    assert @user.tasks.new(title: "期限だけ", due_on: Date.new(2026, 11, 30)).valid?
    assert @user.tasks.new(title: "何もなし").valid?
    assert_not @user.tasks.new(title: "逆転", starts_on: Date.new(2026, 12, 1), due_on: Date.new(2026, 11, 30)).valid?
  end

  test "見積もりは1以上の整数" do
    assert @user.tasks.new(title: "t", estimate_pomodoros: 2).valid?
    assert_not @user.tasks.new(title: "t", estimate_pomodoros: 0).valid?
  end

  test "done で completed_at を出し入れできる" do
    task = @user.tasks.create!(title: "t")
    task.update!(done: true)
    assert task.done?
    assert task.completed_at

    task.update!(done: false)
    assert_not task.done?
    assert_nil task.completed_at
  end

  test "親を消すとサブタスクもまとめて消える" do
    root = @user.tasks.create!(title: "親")
    child = @user.tasks.create!(title: "子", parent: root)
    @user.tasks.create!(title: "孫", parent: child)

    assert_difference -> { Task.count }, -3 do
      root.destroy!
    end
  end
end
