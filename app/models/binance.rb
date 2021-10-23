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

  def symbol(market)
    "#{market.base}#{market.quote}"
  end

  def tickers(market)
    ticker_url = Binance::HOST + '/api/v1/ticker/24hr'
    res = Faraday.get do |req|
      req.url ticker_url
      req.params['symbol'] = market.symbol
    end
    result = JSON.parse(res.body)
    {last: result["lastPrice"].to_f, bid: result["bidPrice"].to_f, ask: result["askPrice"].to_f}
  end

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
    digest = OpenSSL::Digest.new('sha256')
    return OpenSSL::HMAC.hexdigest(digest, app_secret, data)
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
    assets = results.select {|a| a['free'].to_f + a['locked'].to_f > 0 }
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

  def sync_accounts
    accounts.update_all(balance: 0, freezen: 0)
    assets.each do |ac|
      Account.update_or_create_by({exchange_id: id, asset: ac["asset"], balance: ac["free"], freezen: ac["locked"]})
    end
    accounts.map {|x| x.destroy_empty }
  end

  def sync_account(market)
    assets.each do |ac|
      if market.info.include? ac['asset']
        Account.update_or_create_by({exchange_id: id, asset: ac["asset"], balance: ac["free"], freezen: ac["locked"]})
      end
    end
  end

  def trades(asset, quote)
    symbol = asset + quote
    order_url = Binance::HOST + "/api/v3/myTrades"
    timestamp = (Time.now.to_f * 1000).to_i - 2000
    params_string = "limit=1000&recvWindow=10000&symbol=#{symbol}&timestamp=#{timestamp}"
    res = Faraday.get do |req|
      req.url order_url
      req.headers['X-MBX-APIKEY'] = app_key
      req.params['symbol']        = symbol
      req.params['recvWindow']    = 10000
      req.params['limit']         = 1000
      req.params['timestamp']     = timestamp
      req.params['signature']     = params_signed(params_string)
    end
    result = JSON.parse(res.body)
  end

  def all_orders(asset, quote, start_t=nil, end_t=nil)
    symbol = asset + quote
    order_url = Binance::HOST + '/api/v3/allOrders'
    timestamp = (Time.now.to_f * 1000).to_i - 2000
    params_string = "#{'endTime=' + end_t.to_s + '&' if end_t}limit=1000&recvWindow=10000&#{'startTime=' + start_t.to_s + '&' if start_t}symbol=#{symbol}&timestamp=#{timestamp}"
    res = Faraday.get do |req|
      req.url order_url
      req.headers['X-MBX-APIKEY'] = app_key
      req.params['symbol']        = symbol
      req.params['recvWindow']    = 10000
      req.params['limit']         = 1000
      req.params['startTime']     = start_t if start_t
      req.params['endTime']       = end_t if end_t
      req.params['timestamp']     = timestamp
      req.params['signature']     = params_signed(params_string)
    end
    result = JSON.parse(res.body)
  end

  def asset_quote_cost(asset, quote, total)
      all_orders = all_orders(asset, quote)
      total = total
      _fund = 0
      _cost = 0
      _a = []
      time_bids = all_orders.select {|o| o['side'] == 'BUY' && o['executedQty'].to_f > 0 }.reverse
      time_bids.each do |item|
        next if total.round(2) <= _fund.round(2)
        _cost += item["cummulativeQuoteQty"].to_f
        _fund += item["executedQty"].to_f
      end
      _cost / _fund
    rescue
      0
  end

  def sync_order(order)
    begin
      market = order.market
      symbol = market.symbol
      side = {'OrderBid'=> 'BUY', 'OrderAsk'=> 'SELL'}[order.type]
      order_url = Binance::HOST + '/api/v3/order'
      timestamp = (Time.now.to_f * 1000).to_i
      reqs = []
      reqs << ['symbol', symbol]
      reqs << ['side', side]
      reqs << ['type', 'LIMIT']
      reqs << ['price', order.price]
      reqs << ['quantity', order.amount]
      reqs << ['recvWindow', 5000]
      reqs << ['timestamp', timestamp]
      reqs << ['timeInForce', 'GTC']
      reqs_string = reqs.sort.map {|x| x.join('=')}.join('&')
      res = Faraday.post do |req|
        req.url order_url
        req.headers['X-MBX-APIKEY'] = app_key
        req.params['symbol'] = symbol
        req.params['side'] = side
        req.params['type'] = 'LIMIT'
        req.params['quantity'] = order.amount
        req.params['price'] = order.price
        req.params['recvWindow'] = 5000
        req.params['timeInForce'] = 'GTC'
        req.params['timestamp'] = timestamp
        req.params['signature'] = params_signed(reqs_string)
      end
      result = JSON.parse(res.body)
      result['order'] = result['orderId']
      order_result_tip(result, order)
      result
    rescue Exception => detail
      Notice.exception(detail, 'Binance trade order')
    end
  end

  def order_result_tip(result, order)
    detail = order.market.detail
    if result['order']
      tip_string = "\n"
      tip_string << "市场： #{detail}\n"
      tip_string << "类别： #{order.type}\n"
      tip_string << "价格： #{result['price']}\n"
      tip_string << "数量： #{result['origQty']}\n"
      Notice.tip(tip_string)
    elsif result['msg']
      Notice.alarm("#{detail}\n" + result['msg'])
    end
  end

  def delete_open_order(market)
    symbol = market.symbol
    delete_url = Binance::HOST + '/api/v3/openOrders'
    timestamp = (Time.now.to_f * 1000).to_i
    params_string = "recvWindow=5000&symbol=#{symbol}&timestamp=#{timestamp}"
    res = Faraday.delete do |req|
      req.url delete_url
      req.headers['X-MBX-APIKEY'] = app_key
      req.params['symbol'] = symbol
      req.params['recvWindow'] = 5000
      req.params['timestamp'] = timestamp
      req.params['signature'] = params_signed(params_string)
    end
    result = JSON.parse(res.body)
  end

end
