class ApplicationController < ActionController::API
  class InvalidTokenError < StandardError; end

  require 'net/http'

  before_action :valid_token

  #
  # frontからの全てのリクエストに対して、
  # bearerのトークンが正しいかfirebaseに問合せ。
  # 正しくなければエラーを返す。
  #
  def valid_token
    payload = FirebaseAuth::valid_token(
      request,
      ENV['FIREBASE_PROJECT_ID']
    )

    #TODO: ここでpyaloadの処理。新規登録等。
    puts payload

    # firebaseの認証に失敗した場合のrender処理。
    # 現在想定できるErrorは以下の2つだが今後増えたらキャッチも増やす。
  rescue NoMethodError, JWT::DecodeError => e
     Rails.logger.error e.message
     Rails.logger.error e.backtrace.join("\n")

     error = InvalidTokenError.new('authorization error.')

     render json: error, status: :unauthorized
  end
end
