class SessionsController < ApplicationController
  def new
    redirect_to todos_path if logged_in?
  end

  # POST /sessions/options
  def options
    email = params[:email].to_s.strip.downcase
    user = User.find_by(email: email)

    unless user
      return render json: { error: "そのメールアドレスのユーザーは見つからんかったで" }, status: :not_found
    end

    get_options = WebAuthn::Credential.options_for_get(
      allow: user.passkeys.pluck(:external_id)
    )

    session[:webauthn_authentication] = {
      challenge: get_options.challenge,
      user_id: user.id
    }

    render json: get_options
  end

  # POST /sessions
  def create
    authentication = session[:webauthn_authentication]

    unless authentication
      return render json: { error: "ログインセッションが切れてもうた。最初からやり直してや" }, status: :unprocessable_content
    end

    webauthn_credential = WebAuthn::Credential.from_get(params.require(:credential).permit!.to_h)
    passkey = Passkey.find_by(external_id: webauthn_credential.id, user_id: authentication["user_id"])

    unless passkey
      return render json: { error: "パスキーが見つからんかったで" }, status: :unprocessable_content
    end

    begin
      webauthn_credential.verify(
        authentication["challenge"],
        public_key: passkey.public_key,
        sign_count: passkey.sign_count
      )

      passkey.update!(sign_count: webauthn_credential.sign_count)
      session.delete(:webauthn_authentication)
      session[:user_id] = passkey.user_id

      render json: { redirect_to: todos_path }
    rescue WebAuthn::Error => e
      render json: { error: "ログインに失敗したで: #{e.message}" }, status: :unprocessable_content
    end
  end

  def destroy
    reset_session
    redirect_to sign_in_path, notice: "ログアウトしたで"
  end
end
