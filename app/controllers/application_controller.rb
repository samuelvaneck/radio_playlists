# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  before_action :authenticate_admin!
  before_action :maybe_set_refresh_token?

  def refresh_token
    return if current_admin.blank?

    @refresh_token ||= if session[:refresh_token].present?
                         RefreshToken.find_by(session_id:,
                                              token: session[:refresh_token][:token],
                                              admin: current_admin)
                       end
  end

  def session_id
    request.session_options[:id].to_s
  end

  private

  def maybe_set_refresh_token?
    return if request.session_options[:skip]
    return if session_id.blank?

    if refresh_token.present? && refresh_token.expired?
      refresh_token.destroy
      return render json: { error: 'Refresh token expired' }, status: :unauthorized
    elsif refresh_token.present?
      return
    end

    new_token = RefreshToken.create(admin: current_admin, session_id:)
    session[:refresh_token] = { token: new_token.token, expires_at: new_token.expires_at }
  end
end
