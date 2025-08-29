class UsersController < ApplicationController
  load_and_authorize_resource

  before_action :logged_in_user,
                only: %i(show edit update setup_password update_password)
  before_action :load_user, only: %i(show edit update follows)
  before_action :correct_user, only: %i(show edit update)
  before_action :require_password_setup,
                only: %i(setup_password update_password)

  FAVORITE_INCLUDES = %i(author publisher categories image_attachment:
blob).freeze
  AUTHOR_ID = "author_id".freeze
  CATEGORY_ID = "category_id".freeze
  PUBLISHER_ID = "publisher_id".freeze

  # GET /signup
  def new
    @user = User.new
  end

  # POST /signup
  def create
    @user = User.new user_params
    if @user.save
      send_activation_email
    else
      flash.now[:danger] = t(".error")
      render :new, status: :unprocessable_entity
    end
  end

  # GET /users/:id
  def show; end

  # GET /users/:id/edit
  def edit
    @user = current_user
  end

  # PATCH/PUT /users/:id
  def update
    @user = current_user

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
    @user = current_user
    @pagy, @favorite_books = pagy(
      @user.ordered_favorite_books_with_includes,
      items: Settings.pagy.items
    )

    @favorite_stats = calculate_favorite_stats(@user)
  end

  # GET /users/:id/follows
  def follows
    authors_with_includes = @user.ordered_favorite_authors_with_includes

    @pagy, @favorite_authors = pagy(authors_with_includes,
                                    items: Settings.pagy.items)

    @author_stats = calculate_author_stats(@favorite_authors)
  end

  # GET /users/setup_password
  def setup_password
    @user = current_user
  end

  # PATCH/PUT /users/:id/update_password
  def update_password
    @user = current_user

    if @user.update(password_setup_params)
      flash[:success] = t(".password_setup_success")
      redirect_to user_path(@user)
    else
      render :setup_password, status: :unprocessable_entity
    end
  end

  private

  def load_user
    @user = User.find_by id: params[:id]
    return if @user

    flash[:warning] = t(".not_found")
    redirect_to root_path, status: :see_other
  end

  def user_params
    params.require(:user).permit(User::USER_PERMIT)
  end

  def profile_params
    params.require(:user).permit(User::USER_PERMIT_FOR_PROFILE)
  end

  def correct_user
    return if current_user? @user

    flash[:error] = t(".not_correct_user")
    redirect_to root_url
  end

  def send_activation_email
    @user.send_activation_email
    flash[:info] = t(".check_email")
    redirect_to root_path, status: :see_other
  rescue StandardError
    flash[:danger] = t(".email_error")
    redirect_to root_path, status: :see_other
  end

  def password_setup_params
    params.require(:user).permit(User::USER_OAUTH_SETUP_PERMIT)
  end

  def require_password_setup
    return if current_user&.oauth_user?

    flash[:danger] = t(".require_password_setup")
    redirect_to root_path
  end

  def calculate_favorite_stats user
    {
      total_favorites: user.favorite_books.count,
      unique_authors:
      user.favorite_books.joins(:author).distinct.count(AUTHOR_ID),
      unique_categories:
      user.favorite_books.joins(:categories).distinct.count(CATEGORY_ID),
      unique_publishers:
      user.favorite_books.joins(:publisher).distinct.count(PUBLISHER_ID)
    }
  end

  def calculate_author_stats authors
    return {total_books: 0, avg_books: 0} if authors.empty?

    total_books = authors.sum {|author| author.books.size}
    avg_books = (total_books / authors.count.to_f).round(1)

    {
      total_books:,
      avg_books:
    }
  end
end
