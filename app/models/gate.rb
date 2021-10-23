# == Schema Information
#
# Table name: exchanges
#
#  id         :integer          not null, primary key
#  app_key    :string
#  app_secret :string
#  remark     :string
#  type       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :integer
#
class Gate < Exchange
  HOST = 'https://api.gateio.ws/api/v4'

  def symbol(market)
    "#{market.base}_#{market.quote}"
  end

  def account_usdt

  end

  def estimate_usdt
    timestamp = Time.now.to_i.to_s
    get_url = Gate::HOST + "/wallet/total_balance"
    string = "GET\n/api/v4/wallet/total_balance\n\n#{hexencode("")}\n#{timestamp}"
    res = Faraday.get do |req|
      req.url get_url
      req.headers['Content-Type'] = 'application/json'
      req.headers['KEY'] = app_key
      req.headers['Timestamp'] = timestamp
      req.headers['SIGN'] = auth_signed(string)
    end
    result = JSON.parse(res.body)
    result['total']['amount']
  end

  def sync_accounts
    accounts.update_all(balance: 0, freezen: 0)
    assets.each do |ac|
      Account.update_or_create_by({exchange_id: id, asset: ac["currency"], balance: ac["available"], freezen: ac["locked"]})
    end
    accounts.map {|x| x.destroy_empty }
  end

  def sync_account(market)
    assets.each do |ac|
      if market.info.include? ac['currency']
        Account.update_or_create_by({exchange_id: id, asset: ac["currency"], balance: ac["available"], freezen: ac["locked"]})
      end
    end
  end

  def assets
    timestamp = Time.now.to_i.to_s
    get_url = Gate::HOST + "/spot/accounts"
    string = "GET\n/api/v4/spot/accounts\n\n#{hexencode("")}\n#{timestamp}"
    res = Faraday.get do |req|
      req.url get_url
      req.headers['Content-Type'] = 'application/json'
      req.headers['KEY'] = app_key
      req.headers['Timestamp'] = timestamp
      req.headers['SIGN'] = auth_signed(string)
    end
    result = JSON.parse(res.body)
    assets = result.select {|a| a['available'].to_f + a['locked'].to_f > 0}
  end

  def auth_signed(payload)
    digest = OpenSSL::Digest::SHA512.new
    digest_string = OpenSSL::HMAC.digest(digest, app_secret, payload)
    Digest.hexencode digest_string
  end

  def hexencode(payload)
    Digest.hexencode(Digest::SHA512.digest(payload))
  end

  def url_encode(string)
    CGI.escape(string)
  end

  def tickers(market)
    api_url = Gate::HOST + '/spot/tickers'
    res = Faraday.get do |req|
      req.url api_url
      req.params['currency_pair'] = market.symbol
    end
    result = JSON.parse(res.body)[0] || {}
    {last: result["last"].to_f, bid: result["highest_bid"].to_f, ask: result["lowest_ask"].to_f}
  end

  def lists
    api_url = Gate::HOST + '/spot/currency_pairs'
    res = Faraday.get do |req|
      req.url api_url
    end
    result = JSON.parse(res.body)
  end

  def sync_order(order)
    begin
      market = order.market
      timestamp = Time.now.to_i.to_s
      side = {'OrderBid'=> 'buy', 'OrderAsk'=> 'sell'}[order.type]
      order_url = Gate::HOST + "/spot/orders"
      body = {}
      body['currency_pair'] = market.symbol
      body['side'] = side
      body['price'] = order.price.to_s
      body['amount'] = order.amount.to_s
      string = "POST\n/api/v4/spot/orders\n\n#{hexencode(body.to_json)}\n#{timestamp}"
      res = Faraday.post do |req|
        req.url order_url
        req.headers['Content-Type'] = 'application/json'
        req.headers['KEY'] = app_key
        req.headers['Timestamp'] = timestamp
        req.headers['SIGN'] = auth_signed(string)
        req.body = body.to_json
      end
      result = JSON.parse(res.body)
      result['order'] = result['id']
      result['msg'] = result['message']
      order_result_tip(result, order)
      result
    rescue Exception => detail
      Notice.exception(detail, 'Gate trade order')
    end
  end

  def order_result_tip(result, order)
    detail = order.market.detail
    if result['order']
      tip_string = "\n"
      tip_string << "市场： #{detail}\n"
      tip_string << "类别： #{order.type}\n"
      tip_string << "价格： #{result['price']}\n"
      tip_string << "数量： #{result['amount']}\n"
      Notice.tip(tip_string)
    elsif result['msg']
      Notice.alarm(detail + result['msg'])
    end
  end

  def delete_open_order(market)
    symbol = market.symbol
    timestamp = Time.now.to_i.to_s
    delete_url = Gate::HOST + "/spot/orders?account=spot&currency_pair=#{symbol}"
    string = "DELETE\n/api/v4/spot/orders\naccount=spot&currency_pair=#{symbol}\n#{hexencode("")}\n#{timestamp}"
    res = Faraday.delete do |req|
      req.url delete_url
      req.headers['Content-Type'] = 'application/json'
      req.headers['KEY'] = app_key
      req.headers['Timestamp'] = timestamp
      req.headers['SIGN'] = auth_signed(string)
    end
    result = JSON.parse(res.body)
  end

  def asset_quote_cost(asset, quote, total)
    0
  end

end
