# タグの管理（追加・名前変更・削除）。カテゴリ編集と同じ、ふつうの
# Rails 画面。GET /tags.json はタスク画面（Funicular）が絞り込みチップを
# 出すために読む一覧。
class TagsController < ApplicationController
  before_action :require_login
  before_action :set_tag, only: %i[ edit update destroy ]

  def index
    @tags = current_user.tags.ordered
    respond_to do |format|
      format.html
      format.json { render json: @tags.as_json(only: %i[ id name ]) }
    end
  end

  def new
    @tag = current_user.tags.new
  end

  def create
    @tag = current_user.tags.new(tag_params)
    if @tag.save
      redirect_to tags_path, notice: "タグを追加したで"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @tag.update(tag_params)
      redirect_to tags_path, notice: "タグを更新したで"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    @tag.destroy!
    redirect_to tags_path, notice: "タグを削除したで", status: :see_other
  end

  private
    def set_tag
      @tag = current_user.tags.find(params.expect(:id))
    end

    def tag_params
      params.expect(tag: [ :name ])
    end
end
