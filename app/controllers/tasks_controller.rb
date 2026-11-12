# /tasks の HTML は Funicular（PicoRuby.wasm）アプリの入れ物だけを返し、
# 画面はブラウザ側の app/funicular/ で描く。データは /tasks.json 系の JSON API でやり取りする。
class TasksController < ApplicationController
  before_action :require_login
  before_action :set_task, only: %i[ update destroy ]

  # GET /tasks      -> Funicular アプリのページ（どのカテゴリを見るかを画面に埋め込む）
  # GET /tasks.json -> ログインユーザーの、選んでるカテゴリのタスク（フラットな配列。ツリーはクライアントで組む）
  #                    category_id が空なら「すべて」でカテゴリによる絞り込みなし
  def index
    # ヘッダーのカテゴリ切り替えで ?category_id= が付いたときだけ記憶し直す。
    # 付いてなければ（直接 /tasks に来た時など）前回選んでたカテゴリのまま
    session[:active_category_id] = resolved_category_id if params.key?(:category_id)
    @category_id = session[:active_category_id]

    respond_to do |format|
      format.html
      format.json do
        scope = current_user.tasks.ordered.includes(:tags)
        scope = scope.where(category_id: @category_id) if @category_id.present?
        @tasks = scope
      end
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
      params.expect(
        task: [ :title, :parent_id, :category_id, :position, :estimate_pomodoros, :starts_on, :due_on, :done,
                { tag_ids: [] } ]
      )
    end

    # 渡ってきた category_id が自分のカテゴリでなければ無視する（なりすまし対策）
    def resolved_category_id
      id = params[:category_id].presence
      return nil unless id
      current_user.categories.where(id: id).pick(:id)
    end

    def render_errors
      render json: { errors: @task.errors.map(&:message) }, status: :unprocessable_content
    end
end
