require "test_helper"

class TasksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create_user
    sign_in_as @user
  end

  test "未ログインならログイン画面へ" do
    TestSignIn.user = nil
    get tasks_url
    assert_redirected_to sign_in_url
  end

  test "HTML は Funicular アプリの入れ物を返す" do
    get tasks_url
    assert_response :success
    assert_select "div#app"
    assert_select "script[type='application/x-mrb']"
  end

  test "JSON で自分のタスクだけを返す" do
    mine = @user.tasks.create!(title: "私の")
    create_user.tasks.create!(title: "他人の")

    get tasks_url(format: :json)
    assert_response :success
    titles = response.parsed_body.map { |t| t["title"] }
    assert_equal [ mine.title ], titles
    assert_equal %w[ id parent_id position title estimate_pomodoros starts_on due_on completed_at done created_at updated_at ].sort,
                 response.parsed_body.first.keys.sort
  end

  test "サブタスクを作れる" do
    root = @user.tasks.create!(title: "親")
    post tasks_url(format: :json), params: { task: { title: "子", parent_id: root.id, estimate_pomodoros: 1 } }, as: :json
    assert_response :created
    assert_equal root.id, response.parsed_body["parent_id"]
  end

  test "バリデーションエラーはメッセージの配列で返す" do
    post tasks_url(format: :json), params: { task: { title: "" } }, as: :json
    assert_response :unprocessable_content
    assert_includes response.parsed_body["errors"], "タイトルを入れてや"
  end

  test "完了にできる" do
    task = @user.tasks.create!(title: "t")
    patch task_url(task, format: :json), params: { task: { done: true } }, as: :json
    assert_response :success
    assert response.parsed_body["done"]
  end

  test "他人のタスクは更新できない" do
    other = create_user.tasks.create!(title: "他人の")
    patch task_url(other, format: :json), params: { task: { title: "乗っ取り" } }, as: :json
    assert_response :not_found
  end

  test "消すとサブタスクも消える" do
    root = @user.tasks.create!(title: "親")
    @user.tasks.create!(title: "子", parent: root)
    assert_difference -> { Task.count }, -2 do
      delete task_url(root, format: :json)
    end
    assert_response :no_content
  end
end
