ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "funicular/testing"

# tasks/index.html.erb が asset_path("app.mrb") を参照するので、テスト前に app/funicular をコンパイルしておく
Funicular::Testing.ensure_compiled!

module ActiveSupport
  class TestCase
    def create_user(email = "user#{SecureRandom.hex(4)}@example.com")
      User.create!(email: email, webauthn_id: SecureRandom.hex(16))
    end
  end
end

# パスキー認証を通さずにログイン状態を作るためのテスト用フック
module TestSignIn
  mattr_accessor :user
end

ApplicationController.prepend(Module.new do
  private

  def current_user
    TestSignIn.user || super
  end
end)

module ActionDispatch
  class IntegrationTest
    def sign_in_as(user)
      TestSignIn.user = user
    end

    teardown { TestSignIn.user = nil }
  end
end
