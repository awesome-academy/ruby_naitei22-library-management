module ApplicationHelper
  include Pagy::Frontend

  DEFAULT_SEARCH_TYPE = "all".freeze

  SEARCH_TYPE_OPTIONS = [
    %i(search_by_title title),
    %i(search_by_category category),
    %i(search_by_author author),
    %i(search_by_publisher publisher),
    %i(search_all all)
  ].freeze

  def default_search_type
    DEFAULT_SEARCH_TYPE
  end

  def search_type_options_for_select selected = nil
    options = SEARCH_TYPE_OPTIONS.map do |label_key, value|
      [t("books.search.#{label_key}"), value.to_s]
    end

    options_for_select(options, selected)
  end

  def full_title page_title = ""
    base_title = t("layouts.application.base_title")
    page_title.empty? ? base_title : "#{page_title} | #{base_title}"
  end
end
