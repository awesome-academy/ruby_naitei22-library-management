class Admin::ReportsController < Admin::ApplicationController
  authorize_resource class: false

  # Get /admin/reports
  def show
    @borrow_vs_return_percent = borrow_vs_return_percent
    @pagy, @most_borrowed_books = pagy(most_borrowed_books_scope)
  end

  private

  def borrow_vs_return_percent
    total_borrowed = BorrowRequest.borrowed.count
    total_returned = BorrowRequest.returned.count
    total = total_borrowed + total_returned

    {
      I18n.t("admin.reports.show.borrowed") => percent(total_borrowed, total),
      I18n.t("admin.reports.show.returned") => percent(total_returned, total)
    }
  end

  def percent part, total
    total.positive? ? (part.to_f / total * 100).round(2) : 0
  end

  def most_borrowed_books_scope
    Book.most_borrowed(
      month: params[:month],
      year: params[:year]
    ).includes(:author)
  end
end
