# == Schema Information
#
# Table name: climaxes
#
#  id         :integer          not null, primary key
#  magnife    :integer
#  market     :string
#  volumes    :decimal(, )
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Climax < ActiveRecord::Base
  HOST = 'https://api.binance.com'
  has_many :timelimes, dependent: :destroy

  validates_uniqueness_of :market

  # 15m 1h 4h 1d 1w
  # https://binance-docs.github.io/apidocs/spot/cn/#k
  def kline(interval = '15m')
    ticker_url = Binance::HOST + '/api/v3/klines'
    res = Faraday.get do |req|
      req.url ticker_url
      req.params['symbol'] = market
      req.params['interval'] = interval
    end
    result = JSON.parse(res.body)
  end

  def ave_4h_volumes_of_3w
    vols_3w = kline('4h')[-74..-2]
    vols_ary = vols_3w.map { |x| x[5].to_f }
    vols_ary.sum / vols_ary.size
  end

  def sync_volumes
    self.volumes = ave_4h_volumes_of_3w.to_i
    save
  end

  def today_count
    timelimes.where("completed_at > ?", Time.now.beginning_of_day).count
  end

  def price_24h
    ticker_url = Binance::HOST + '/api/v3/ticker/24hr'
    res = Faraday.get do |req|
      req.url ticker_url
      req.params['symbol'] = market
    end
    result = JSON.parse(res.body)
  end

  def climax_kline(kline)
    if kline[5].to_f / volumes > magnife
      generate_timelime(kline)
      content = "\r #{market} 15分K成交放量倍率#{(kline[5].to_f / volumes).round(2)} \r当前价格 #{kline[4].to_f} 成交量 #{kline[5].to_f} 涨幅#{price_24h['priceChangePercent']}% \r 今日放量统计 #{today_count}"
      Notice.tip(content)
    end
  end

  def generate_timelime(kline)
    limes = timelimes.new
    limes.o_price = kline[1]
    limes.h_price = kline[2]
    limes.l_price = kline[3]
    limes.c_price = kline[4]
    limes.volumes = kline[5]
    limes.turnover = kline[7]
    limes.base_vols = volumes
    limes.completed_at = Time.at kline[6] / 1000 + 1
    limes.save
  end

  def backtest
    kline.map {|x| climax_kline(x)}
  end

  def self.touch_kline
    Climax.all.each do |market|
      last_15k = market.kline[-2]
      market.climax_kline(last_15k)
    end
  end

  def self.sync_volumes
    Climax.all.each do |market|
      market.update(volumes: market.ave_4h_volumes_of_3w.to_i)
    end
  end

  def self.busd_market_list
    ticker_url = Binance::HOST + '/api/v3/exchangeInfo'
    res = Faraday.get do |req|
      req.url ticker_url
    end
    result = JSON.parse(res.body)
    symbols = result['symbols'].select {|x| x['quoteAsset'] == 'BUSD'}
  end

  def self.sync_busd_market
    busd_market_list.each do |market|
      Climax.find_or_create_by(market: market['symbol']) do |climax|
        climax.volumes = climax.ave_4h_volumes_of_3w.to_i
        climax.magnife = 3
      end
    end
  end

end
