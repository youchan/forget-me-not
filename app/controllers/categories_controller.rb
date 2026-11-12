# カテゴリの管理（追加・名前変更・削除）。タスク画面とは別の、ふつうの
# Rails 画面（Turboでの遷移のみ。Funicular は使わない）。
class CategoriesController < ApplicationController
  before_action :require_login
  before_action :set_category, only: %i[ edit update destroy ]

  def index
    @categories = current_user.categories.ordered
  end

  def new
    @category = current_user.categories.new
  end

  def create
    @category = current_user.categories.new(category_params)
    if @category.save
      redirect_to categories_path, notice: "カテゴリを追加したで"
    else
      render :new, status: :unprocessable_content
    end
  end

  def edit
  end

  def update
    if @category.update(category_params)
      redirect_to categories_path, notice: "カテゴリを更新したで"
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    if @category.destroy
      redirect_to categories_path, notice: "カテゴリを削除したで", status: :see_other
    else
      redirect_to categories_path, alert: @category.errors.full_messages.to_sentence, status: :see_other
    end
  end

  private
    def set_category
      @category = current_user.categories.find(params.expect(:id))
    end

    def category_params
      params.expect(category: [ :name ])
    end
end
