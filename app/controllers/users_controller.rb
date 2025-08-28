class UsersController < ApplicationController
  before_action :authenticate_user!
  load_and_authorize_resource

  FAVORITE_INCLUDES = %i(author publisher categories image_attachment:
blob).freeze
  AUTHOR_ID = "author_id".freeze
  CATEGORY_ID = "category_id".freeze
  PUBLISHER_ID = "publisher_id".freeze

  # GET /users/:id
  def show; end

  # GET /users/:id/edit
  def edit; end

  # PATCH/PUT /users/:id
  def update
    # Remove blank password fields to avoid validation issues
    update_params = profile_params
    if update_params[:password].blank? &&
       update_params[:password_confirmation].blank?
      update_params.delete(:password)
      update_params.delete(:password_confirmation)
    end

    if @user.update(update_params)
      flash[:success] = t(".profile_updated_successfully")
      redirect_to @user
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # GET /users/:id/favorites
  def favorites
    authorize! :favorites, @user
    @pagy, @favorite_books = pagy(
      @user.ordered_favorite_books_with_includes,
      items: Settings.pagy.items
    )

    @favorite_stats = calculate_favorite_stats(@user)
  end

  # GET /users/:id/follows
  def follows
    authorize! :follows, @user

    authors_with_includes = @user.ordered_favorite_authors_with_includes

    @pagy, @favorite_authors = pagy(authors_with_includes,
                                    items: Settings.pagy.items)

    @author_stats = calculate_author_stats(@favorite_authors)
  end

  private

  def profile_params
    params.require(:user).permit(User::USER_PERMIT_FOR_PROFILE)
  end

  def calculate_favorite_stats user
    {
      total_favorites: user.favorite_books.count,
      unique_authors: user.favorite_books.joins(:author).distinct.count(AUTHOR_ID), # rubocop:disable Layout/LineLength
      unique_categories: user.favorite_books.joins(:categories).distinct.count(CATEGORY_ID), # rubocop:disable Layout/LineLength
      unique_publishers: user.favorite_books.joins(:publisher).distinct.count(PUBLISHER_ID) # rubocop:disable Layout/LineLength
    }
  end

  def calculate_author_stats authors
    return {total_books: 0, avg_books: 0} if authors.empty?

    total_books = authors.sum {|author| author.books.size}
    avg_books   = (total_books / authors.count.to_f).round(1)

    {total_books:, avg_books:}
  end
end
