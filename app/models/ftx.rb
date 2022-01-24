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

  def symbol(market)
    "#{market.base}-#{market.quote}"
  end

  def auth_signed(payload)
    digest = OpenSSL::Digest::SHA256.new
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

  def all_orders(market, start_time = nil, end_time = nil)
    get_path = "/orders/history?"
    get_path << "end_time=#{end_time}&" if end_time
    get_path << "market=#{market.symbol}"
    get_path << "&start_time=#{start_time}" if start_time
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
    return result['result'] if result['result']
    return result['error'] if result['error']
  end

  def all_trades(market, start_time = nil, end_time = nil)
    get_path = "/conditional_orders/history?"
    get_path << "end_time=#{end_time}&" if end_time
    get_path << "market=#{market.symbol}"
    get_path << "&start_time=#{start_time}" if start_time
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
    return result['result'] if result['result']
    return result['error'] if result['error']
  end

  # 根据参数获取最新和历史数据 period [recent history]
  def cache_trades(market, period = 'recent')
    continue = true; start_time = nil; end_time = nil
    if market.trades.size > 0
      start_time = market.trades.recent.first.stimestamp if period == 'recent'
      end_time   = market.trades.history.first.stimestamp if period == 'history'
    end
    while continue
      Notice.tip("[#{market.detail}] 执行拉取交易记录参数 start_time [#{start_time}] end_time [#{end_time}]") if start_time || end_time
      lists = all_orders(market, start_time, end_time)
      trigger_lists = lists&.select {|x| x['filledSize'].to_i > 0}
      trigger_lists.each do |item|
        check_and_create_trade(market, item)
      end
      continue = false if lists.size < 100
      if start_time.blank?
        end_time = lists[-1]['createdAt'].to_time.to_i if lists.size > 0
      else
        start_time = lists[0]['createdAt'].to_time.to_i if lists.size > 0
      end
    end
    if market.trades.size > 0
      Notice.tip("[#{market.detail}] 当前同步交易记录 [#{market.trades.size}] 条")
    end
  end

  def check_and_create_trade(market, attributes)
    trade = Trade.find_or_create_by(market_id: market.id, number: attributes['id'])
    return false if trade.completed_at
    trade.amount = attributes['filledSize'].to_f
    trade.price = attributes['avgFillPrice'].to_f
    trade.total = attributes['filledSize'].to_f * attributes['avgFillPrice'].to_f
    trade.completed_at = attributes['createdAt'].to_time
    trade.timestamp = (attributes['createdAt'].to_time.to_f * 1000).to_i
    trade.cate = attributes['side'] == 'buy' ? 'bid' : 'ask'
    trade.save
    true
  end

end