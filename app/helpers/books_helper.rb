module BooksHelper
  SEARCH_TYPES = [
    ["all", I18n.t("books.search.search_all")],
    ["title", I18n.t("books.search.search_by_title")],
    ["author", I18n.t("books.search.search_by_author")],
    ["publisher", I18n.t("books.search.search_by_publisher")],
    ["category", I18n.t("books.search.search_by_category")]
  ].freeze

  FILTER_OPTIONS = [
    ["newest", I18n.t("books.search.newest_books")],
    ["most_borrow_count", I18n.t("books.search.most_borrowed_books")],
    ["highest_rating", I18n.t("books.search.highest_rating_books")]
  ].freeze

  def search_type_options
    SEARCH_TYPES
  end

  def filter_options
    FILTER_OPTIONS
  end

  def current_search_type_label type_param
    option = SEARCH_TYPES.find {|value, _| value == type_param}
    option ? option[1] : I18n.t("books.search.search_all")
  end

  def current_filter_label filter_param
    option = FILTER_OPTIONS.find {|value, _| value == filter_param}
    option ? option[1] : I18n.t("books.search.newest_books")
  end
end
