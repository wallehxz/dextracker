class Backend::TradesController < Backend::BaseController
  before_action :find_market

  def index
    @trades = @market.trades.history.paginate(page:params[:page])
  end

  def pull
    @market.cache_trades
    flash[:notice] = "市场交易记录同步 [#{@market.trades.size}] 条"
    redirect_to :back
  end

private

  def find_market
    @market = Market.find(params[:market_id])
  end
end