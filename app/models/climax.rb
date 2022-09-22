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

  def climax_kline(kline)
    if kline[5].to_f / volumes > magnife
      tip = "#{market} 15分K成交放量倍率#{(kline[5].to_f / volumes).round(2)} 当前价格 #{kline[4].to_f} 成交量 #{kline[5].to_f}"
      Notice.wechat(tip)
      generate_timelime(kline)
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

end
