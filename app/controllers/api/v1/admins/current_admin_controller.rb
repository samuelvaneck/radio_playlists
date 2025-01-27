# frozen_string_literal: true

class Api::V1::Admins::CurrentAdminController < ApplicationController
  def show
    render json: AdminSerializer.new(current_admin).serializable_hash[:data][:attributes], status: :ok
  end
end
