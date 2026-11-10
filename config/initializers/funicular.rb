# frozen_string_literal: true

# app/funicular は PicoRuby.wasm 用のコードなので、Rails（CRuby）の自動読み込み対象から外す
Rails.autoloaders.main.ignore(Rails.root.join("app/funicular"))

# picoruby_include_tag が PicoRuby.wasm をどこから読むか
#   :local_debug - public/picoruby/debug/init.iife.js（`bin/rails funicular:install:wasm` で配置。エラーが読みやすい）
#   :local_dist  - public/picoruby/dist/init.iife.js
#   :cdn         - jsDelivr の @picoruby/wasm-wasi（gem に同梱されたのと同じバージョン）
#
# 本番は CDN にして、public/picoruby（約4MB）をリポジトリに入れずに済ませている。
#
# 開発・テストも :local_debug ではなく :local_dist にしている。
# デバッグ版の picoruby.wasm（4.0.5）は Chrome 155（V8 15.5, Linux x86_64）で
# 読み込みの数秒後にタブごと落ちる（SIGILL）。リリース版では起きない。
Funicular.configure do |config|
  config.development_source = :local_dist
  config.test_source = :local_dist
  config.production_source = :cdn
end
