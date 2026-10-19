class RegistrationsController < ApplicationController
  def new
    redirect_to todos_path if logged_in?
  end

  # POST /registrations/options
  def options
    email = params[:email].to_s.strip.downcase

    unless email.match?(URI::MailTo::EMAIL_REGEXP)
      return render json: { error: "メールアドレスの形式が正しくないで" }, status: :unprocessable_content
    end

    if User.exists?(email: email)
      return render json: { error: "このメールアドレスはもう登録済みやで" }, status: :unprocessable_content
    end

    webauthn_id = WebAuthn.generate_user_id

    create_options = WebAuthn::Credential.options_for_create(
      user: { id: webauthn_id, name: email, display_name: email }
    )

    session[:webauthn_registration] = {
      challenge: create_options.challenge,
      email: email,
      webauthn_id: webauthn_id
    }

    render json: create_options
  end

  # POST /registrations
  def create
    registration = session[:webauthn_registration]

    unless registration
      return render json: { error: "登録セッションが切れてもうた。最初からやり直してや" }, status: :unprocessable_content
    end

    webauthn_credential = WebAuthn::Credential.from_create(params.require(:credential).permit!.to_h)

    begin
      webauthn_credential.verify(registration["challenge"])

      user = nil
      ActiveRecord::Base.transaction do
        user = User.create!(email: registration["email"], webauthn_id: registration["webauthn_id"])
        user.passkeys.create!(
          external_id: webauthn_credential.id,
          public_key: webauthn_credential.public_key,
          sign_count: webauthn_credential.sign_count,
          nickname: params[:nickname].presence || "パスキー"
        )
      end

      session.delete(:webauthn_registration)
      session[:user_id] = user.id

      render json: { redirect_to: todos_path }
    rescue WebAuthn::Error => e
      render json: { error: "パスキーの登録に失敗したで: #{e.message}" }, status: :unprocessable_content
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.record.errors.full_messages.join(", ") }, status: :unprocessable_content
    end
  end
end
