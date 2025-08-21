class UserMailer < ApplicationMailer
  # def account_activation user
  #   @user = user

  #   mail to: user.email, subject: t("user_mailer.activation_subject")
  # end

  # def password_reset user
  #   @user = user
  #   mail to: user.email, subject: t("password_resets.activation_subject")
  # end

  def borrow_request_approved borrow_request
    @user = borrow_request.user
    @borrow_request = borrow_request
    @books = borrow_request.books

    mail(
      to: @user.email,
      subject: t("user_mailer.borrow_request_approved_subject")
    )
  end

  def borrow_request_rejected borrow_request
    @user = borrow_request.user
    @borrow_request = borrow_request
    @books = borrow_request.books

    mail(
      to: @user.email,
      subject: t("user_mailer.borrow_request_rejected_subject")
    )
  end
end
