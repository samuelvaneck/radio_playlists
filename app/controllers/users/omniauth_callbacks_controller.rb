class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController

  def spotify
    # You need to implement the method below in your model (e.g. app/models/user.rb)
    # @spotify_user = RSpotify::User.new(request.env['omniauth.auth'])
    @spotify_user = User.from_omniauth(request.env['omniauth.auth'])

    if @spotify_user.persisted?
      sign_in_and_redirect @spotify_user, event: :authentication #this will throw if @user is not activated
      set_flash_message(:notice, :success, kind: "Spotify") if is_navigational_format?
    else
      session["devise.spotify_data"] = request.env["omniauth.auth"]
      redirect_to new_user_registration_url
    end
  end

  def failure
    redirect_to root_path
  end

end
