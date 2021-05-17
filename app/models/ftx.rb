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
class Ftx < Exchange

  HOST = 'https://ftx.com/api'

  def auth_signed(payload)
    digest = OpenSSL::Digest.new('sha256')
    OpenSSL::HMAC.hexdigest(digest, app_secret, payload)
  end

  def get_all_balances
    get_path = "/wallet/all_balances"
    host_url = "#{HOST}#{get_path}"
    timestamp = (Time.now.to_f * 1000).to_i.to_s
    signed_string = auth_signed("#{timestamp}GET#{URI(host_url).request_uri}")
    res = Faraday.get do |req|
      req.url host_url
      req.headers['FTX-KEY']  = app_key
      req.headers['FTX-TS']   = timestamp
      req.headers['FTX-SIGN'] = signed_string
    end
    result = JSON.parse(res.body)
  end

  def estimate_usdt
    lists = get_all_balances['result']
    valids = []
    lists.each do |account, _balances|
      _balances.each do |balance|
        valids << balance['usdValue'] if balance['usdValue'] != 0
      end
    end
    valids.sum
  end

end
