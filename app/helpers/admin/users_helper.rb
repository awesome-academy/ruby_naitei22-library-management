# app/helpers/admin/users_helper.rb
module Admin::UsersHelper
  USER_STATUS_COLORS = {
    "inactive" => "status-inactive",
    "active" => "status-active"
  }.freeze

  def user_status_color status
    USER_STATUS_COLORS[status] || "status-default"
  end

  def opposite_user_status_color status
    opposite_status = status == "active" ? "inactive" : "active"
    USER_STATUS_COLORS[opposite_status] || "status-default"
  end

  def age_of user
    return unless user.date_of_birth

    now = Time.zone.today
    dob = user.date_of_birth
    age = now.year - dob.year
    age -= 1 if now < dob + age.years
    age
  end

  def user_search_inputs
    [
      {attr: :name_cont, type: :search, label: t(".search_name"),
       placeholder: t(".search_name_placeholder")},
      {attr: :email_cont, type: :search, label: t(".search_email"),
       placeholder: t(".search_email_placeholder")},
      {attr: :confirmed_at_present, type: :select, label: t(".status"),
       options: [
         [t(".active"), true],
         [t(".inactive"), false]
       ],
       include_blank: t(".all")}
    ]
  end
end
