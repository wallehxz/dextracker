# == Schema Information
#
# Table name: exchanges
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  app_key    :string
#  app_secret :string
#  type       :string
#  remark     :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Binance < Exchange
  HOST = 'https://api.binance.com'

  def account_snapshot
    api_url = Binance::HOST + '/sapi/v1/accountSnapshot'
    timestamp = (Time.now.to_f * 1000).to_i
    params_stirng = "limit&recvWindow=10000&timestamp=#{timestamp}&type=SPOT"
    res = Faraday.get do |req|
      req.url api_url
      req.headers['X-MBX-APIKEY'] = app_key
      req.params['limit']         = 30
      req.params['recvWindow']    = 10000
      req.params['signature']     = params_signed(params_stirng)
      req.params['timestamp']     = timestamp
      req.params['type']          = 'SPOT'
    end
    JSON.parse(res.body)['snapshotVos']
  end

  def params_signed(data)
    secret = app_secret
    digest = OpenSSL::Digest.new('sha256')
    return OpenSSL::HMAC.hexdigest(digest, secret, data)
  end

  def assets
    api_url = Binance::HOST + '/api/v3/account'
    timestamp = (Time.now.to_f * 1000).to_i
    params_stirng = "recvWindow=10000&timestamp=#{timestamp}"
    res = Faraday.get do |req|
      req.url api_url
      req.headers['X-MBX-APIKEY'] = app_key
      req.params['recvWindow']    = 10000
      req.params['timestamp']     = timestamp
      req.params['signature']     = params_signed(params_stirng)
    end
    results = JSON.parse(res.body)['balances']
    assets = results.select {|a| a['free'].to_f + a['locked'].to_f > 0}
  end

  # {"asset"=>"YFI", "free"=>"0.00001494", "locked"=>"0.00000000"}
  def asset_to_usdt(asset)
    return asset['free'].to_f + asset['locked'].to_f if asset['asset'] == 'USDT'
    (asset['free'].to_f + asset['locked'].to_f) * fetch_price("#{asset['asset']}USDT")
  end

  def fetch_price(symbol)
    api_url = Binance::HOST + '/api/v3/avgPrice'
    res = Faraday.get do |req|
      req.url api_url
      req.params['symbol'] = symbol
    end
    JSON.parse(res.body)['price'].to_f
  end

  def estimate_usdt
    assets.map { |asset| asset_to_usdt(asset) }.sum
  end

end
