class Ability
  include CanCan::Ability

  def initialize user
    user ||= User.new

    if user.admin?
      admin_abilities(user)
    elsif user.persisted?
      user_abilities(user)
    else
      guest_abilities
    end
  end

  private

  def admin_abilities user
    can :manage, Book
    can :manage, Author
    can :manage, Category
    can :manage, Publisher
    can :manage, BorrowRequest
    can :read, :report

    can %i(show edit update), User, id: user.id
    can %i(read create update destroy), User
  end

  def user_abilities user
    can :access, :user_area

    book_actions
    borrow_request_actions(user)
    review_actions(user)
    user_profile_actions(user)
  end

  def guest_abilities
    can :read, Book
    can :search, Book
    can :read, Author
  end

  def book_actions
    can :search, Book
    can :borrow, Book
    can :add_to_favorite, Book
    can :remove_from_favorite, Book
    can :add_to_favorite, Author
    can :remove_from_favorite, Author
  end

  def borrow_request_actions user
    can :create, BorrowRequest
    can %i(read update destroy), BorrowRequest, user_id: user.id
    can :checkout, BorrowRequest
  end

  def review_actions user
    can :create, Review do |review|
      review.book_id.present? &&
        user.borrow_requests
            .where(status: %i(approved returned borrowed))
            .joins(:borrow_request_items)
            .where(borrow_request_items: {book_id: review.book_id})
            .exists?
    end

    can %i(update destroy), Review, user_id: user.id
    can :read, Review
  end

  def user_profile_actions user
    can %i(show edit update), User, id: user.id
    can :favorites, User, id: user.id
    can :follows, User, id: user.id
  end
end
