class Backend::PeriodsController < Backend::BaseController
  before_action :find_market

  def index
    @periods = @market.periods.recent.closs.paginate(page:params[:page])
  end

  def trades
    @trades = @period.trades.recent.paginate(page:params[:page])
  end

  def grand
    continue = true
    while continue
      period = @market.periods.holds.first || @market.periods.create
      period.grand_trades
      continue = false if @market.trades.where(period: nil).blank?
    end
    flash[:notice] = "统计交易周期 [#{@market.periods.size}] 条"
    redirect_to :back
  end

private

  def find_market
    @market = Market.find(params[:market_id])
  end
end