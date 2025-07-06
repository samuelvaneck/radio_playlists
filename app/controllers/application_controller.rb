# frozen_string_literal: true

class ApplicationController < ActionController::Base
  protect_from_forgery with: :null_session

  before_action :authenticate_admin!
  before_action :maybe_set_refresh_token


  private
  def maybe_set_refresh_token
    return if current_admin.blank?
    return if request.session_options[:skip]

    session_id = request.session_options[:id]
    return if request.session_options[:id].blank?

    refresh_token = session[:refresh_token]
    return if refresh_token.present?

    session[:refresh_token] = RefreshToken.create(admin: current_admin, session_id:)
  end
end
