module SessionHelpers
  def log_in_as(user)
    session[:user_id] = user.id
  end
end

RSpec.configure do |config|
  config.include SessionHelpers, type: :controller
  config.include SessionHelpers, type: :request
end
