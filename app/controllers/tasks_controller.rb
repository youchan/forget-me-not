# /tasks の HTML は Funicular（PicoRuby.wasm）アプリの入れ物だけを返し、
# 画面はブラウザ側の app/funicular/ で描く。データは /tasks.json 系の JSON API でやり取りする。
class TasksController < ApplicationController
  before_action :require_login
  before_action :set_task, only: %i[ update destroy ]

  # GET /tasks      -> Funicular アプリのページ
  # GET /tasks.json -> ログインユーザーの全タスク（フラットな配列。ツリーはクライアントで組む）
  def index
    respond_to do |format|
      format.html
      format.json { @tasks = current_user.tasks.ordered }
    end
  end

  # POST /tasks.json
  def create
    @task = current_user.tasks.new(task_params)

    if @task.save
      render :show, status: :created
    else
      render_errors
    end
  end

  # PATCH /tasks/:id.json
  def update
    if @task.update(task_params)
      render :show
    else
      render_errors
    end
  end

  # DELETE /tasks/:id.json （サブタスクもまとめて消える）
  def destroy
    @task.destroy!
    head :no_content
  end

  private
    def set_task
      @task = current_user.tasks.find(params.expect(:id))
    end

    def task_params
      params.expect(task: [ :title, :parent_id, :position, :estimate_pomodoros, :starts_on, :due_on, :done ])
    end

    def render_errors
      render json: { errors: @task.errors.map(&:message) }, status: :unprocessable_content
    end
end
