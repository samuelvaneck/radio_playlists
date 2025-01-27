# frozen_string_literal: true

class AdminSerializer
  include FastJsonapi::ObjectSerializer

  attributes :uuid, :email
end
