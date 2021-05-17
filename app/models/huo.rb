class Huo < Exchange
  HOST = 'https://api-aws.huobi.pro'

  def account_usdt
    get_path = "/v2/account/asset-valuation"
    utc_time = Time.now.utc.strftime("%FT%T")
    sign_string = "GET\n"
    sign_string << "api-aws.huobi.pro\n"
    sign_string << "/v2/account/asset-valuation\n"
    params = []
    params << ['accountType', 'spot']
    params << ['valuationCurrency', 'USD']
    params << ['AccessKeyId', app_key]
    params << ['SignatureMethod', 'HmacSHA256']
    params << ['SignatureVersion', 2]
    params << ['Timestamp', url_encode(Time.now.utc.strftime("%FT%T"))]
    params_string = params.map {|i| "#{i[0]}=#{i[1]}"}.sort.join("&")
    sign_string << params_string
    signed = auth_signed(sign_string)
    signed_base64 = Base64.encode64 signed
    params_string << "&Signature=#{signed_base64.chomp}"
    url_string = HOST + get_path + '?' + params_string
    res = Faraday.get(url_string)
    res.body
    result = JSON.parse(res.body)
  end

  def estimate_usdt
    http_success = false
    balance = 0
    http_count = 1
    until http_success
      puts "网络请求次数统计：#{http_count}"
      data = account_usdt
      if data['ok']
        balance = data['data']['balance']
        http_success = true
      end
      http_count += 1
    end
    balance
  end

  def auth_signed(payload)
    digest = OpenSSL::Digest.new('sha256')
    OpenSSL::HMAC.digest(digest, app_secret, payload)
  end

  def url_encode(string)
    CGI.escape(string)
  end

end