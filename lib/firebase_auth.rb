module FirebaseAuth
  CERTS_URI = 'https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com'
  ISSUER_URI_BASE = 'https://securetoken.google.com/'

  class << self

    def valid_token(request, firebase_project_id)
      token = request.headers['Authorization'].split(' ').last

      payload, _ = JWT.decode(token, nil, true, {
        algorithm: 'RS256',
        iss: ISSUER_URI_BASE + firebase_project_id,
        verify_iss: true,
        aud: firebase_project_id,
        verify_aud: true,
        verify_iat: true,
      }) do |header|
        cert = fetch_certificates[header['kid']]
        if cert.present?
          OpenSSL::X509::Certificate.new(cert).public_key
        else
          nil
        end
      end

      return payload
    end

    private

    # 毎度取得せずにキャッシュさせるためには、redisを使用。asw上でも必要。
    def fetch_certificates
      #cached = Rails.cache.read(CERTS_CACHE_KEY)
      #return cached if cached.present?

      res = Net::HTTP.get_response(URI(CERTS_URI))
      raise 'Fetch certificates error' unless res.is_a?(Net::HTTPSuccess)

      body = JSON.parse(res.body)
      #expires_at = Time.zone.parse(res.header['expires'])
      #Rails.cache.write(CERTS_CACHE_KEY, body, expires_in: expires_at - Time.current)

      body
    end

  end
end
