class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def not_found
    raise ActionController::RoutingError.new('Not Found')
  end

  def append_info_to_payload(payload)
    super
    payload[:remote_ip]  = request.remote_ip
    payload[:user_agent] = request.user_agent
  end
end
