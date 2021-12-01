class Backend::MarketsController < Backend::BaseController
  before_action :find_exchange
  def index
    @markets = @exchange.markets.paginate(page:params[:page])
  end

  def new
  end

  def create
    @market = @exchange.markets.new(market_params)
    if @market.save
      redirect_to backend_exchange_markets_path(@exchange), notice: '新交易市场添加成功'
    else
      flash[:warn] = "请完善表单信息"
      render :new
    end
  end

  def edit
  end

  def update
    if @market.update(market_params)
      redirect_to backend_exchange_markets_path(@exchange), notice: '交易市场更新成功'
    else
      flash[:warn] = "请完善表单信息"
      render :edit
    end
  end

  def destroy
    @market.destroy
    flash[:notice] = "交易市场删除成功"
    redirect_to :back
  end

private
  def find_exchange
    @exchange = Exchange.find(params[:exchange_id])
  end

  def market_params
    params.require(:market).permit(:base, :quote, :exchange_id, :precision)
  end
end