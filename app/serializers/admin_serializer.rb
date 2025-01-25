# frozen_string_literal: true

class AdminSerializer
  include FastJsonapi::ObjectSerializer

  attributes :id, :email
end
