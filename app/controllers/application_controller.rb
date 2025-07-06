# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  before_action :authenticate_admin!
  before_action :maybe_set_refresh_token?

  private

  def maybe_set_refresh_token?
    return if current_admin.blank?
    return if request.session_options[:skip]

    session_id = request.session_options[:id]
    return if request.session_options[:id].blank?

    current_refresh_token = session[:refresh_token]
    if current_refresh_token.present? && current_refresh_token[:expires_at] > Time.zone.now
      RefreshToken.find_by(token: current_refresh_token[:token], session_id:, admin: current_admin)&.destroy
    elsif current_refresh_token.present? && current_refresh_token[:expires_at] < Time.zone.now
      return
    end

    new_token = RefreshToken.create(admin: current_admin, session_id:)
    session[:refresh_token] = { token: new_token.token,
                                expires_at: new_token.expires_at }
  end
end
