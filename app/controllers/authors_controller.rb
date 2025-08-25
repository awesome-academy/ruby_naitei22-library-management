class AuthorsController < ApplicationController
  before_action :set_author,
                only: %i(show add_to_favorite remove_from_favorite)
  before_action :set_book_by_author, only: :show
  before_action :load_favorite, only: %i(remove_from_favorite)

  # GET /authors/:id
  def show; end

  # POST /authors/:id/add_to_favorite
  def add_to_favorite # rubocop:disable Metrics/AbcSize
    @favorite ||= current_user.favorites.new(favorable: @author)

    respond_to do |format|
      if @favorite.save
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "favorite_button_#{@author.model_name.singular}_#{@author.id}",
            partial: "books/favorite_button",
            locals: {item: @author}
          )
        end
        format.html do
          redirect_to author_path(@author),
                      notice: t("authors.show.favorite_success")
        end
      else
        format.html do
          redirect_to author_path(@author),
                      alert: t("authors.show.favorite_failed")
        end
      end
    end
  end

  # DELETE /authors/:id/remove_from_favorite
  def remove_from_favorite
    respond_to do |format|
      if @favorite.destroy
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "favorite_button_#{@author.model_name.singular}_#{@author.id}",
            partial: "books/favorite_button",
            locals: {item: @author}
          )
        end
        format.html do
          redirect_to author_path(@author),
                      notice: t("authors.show.unfavorite_success")
        end
      else
        format.html do
          redirect_to author_path(@author),
                      alert: t("authors.show.unfavorite_failed")
        end
      end
    end
  end

  private
  def set_author
    @author = Author.find_by(id: params[:id])
    return if @author

    flash[:alert] = t("authors.show.author_not_found")
    redirect_to root_path
  end

  def set_book_by_author
    books_by_author = Book.by_author(@author.id)
    @pagy_books, @recommended_books = pagy(
      books_by_author,
      items: Settings.digits.digit_12,
      page_param: :recommended_page,
      overflow: :last_page
    )
  end

  def load_favorite
    @favorite = current_user.favorites.find_by(favorable: @author)
    return if @favorite

    flash[:alert] = t("authors.show.favorite_not_found")
    redirect_to author_path(@author)
  end
end
