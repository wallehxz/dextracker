class Backend::DashboardsController < Backend::BaseController


  # {"symbol"=>"HNTUSDT",
  # "markPrice"=>"22.02582277",
  # "indexPrice"=>"21.97602719",
  # "estimatedSettlePrice"=>"21.92391564",
  # "lastFundingRate"=>"0.00112039",
  # "interestRate"=>"0.00010000",
  # "nextFundingTime"=>1635264000000,
  # "time"=>1635242236000}

  def bnb_rate
    fund_rate_url = 'https://fapi.binance.com/fapi/v1/premiumIndex'
    res = Faraday.get do |req|
      req.url fund_rate_url
    end
    result = JSON.parse(res.body)
    @rates = result.sort { |y,x| x['lastFundingRate'].to_f <=> y['lastFundingRate'].to_f }.map(&:symbolize_keys)
  end

  def ftx_rate
    fund_rate_url = 'https://ftx.com/api/funding_rates'
    res = Faraday.get do |req|
      req.url fund_rate_url
    end
    result = JSON.parse(res.body)['result']
    @rates = result.sort { |y,x| x['rate'].to_f <=> y['rate'].to_f }.map(&:symbolize_keys)
  end
end
