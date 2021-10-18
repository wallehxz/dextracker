class Backend::OrdersController < Backend::BaseController
  before_action :find_market

  def index
    @orders = @market.orders.recent.paginate(page:params[:page])
  end

  def new
  end

  def create
    @order = Order.new(order_params)
    if @order.save
      redirect_to backend_market_orders_path(@market), notice: '新市场订单添加成功'
    else
      flash[:warn] = "请完善表单信息"
      render :new
    end
  end

  def edit
  end

  def update
    if @order.update(order_type_params)
      redirect_to backend_market_orders_path(@market), notice: '市场订单更新成功'
    else
      flash[:warn] = "请完善表单信息"
      render :edit
    end
  end

  def destroy
    @order.destroy
    flash[:notice] = "市场订单删除成功"
    redirect_to :back
  end

  def push
    @order.push
    flash[:notice] = "市场订单推送成功"
    redirect_to :back
  end

private

  def find_market
    @market = Market.find(params[:market_id])
  end

  def order_params
    params.require(:order).permit(:exchange_id, :market_id, :amount, :price, :type, :state)
  end

  def order_type_params
    [:order_bid, :order_ask].each do |order_type|
      return params.require(order_type).permit(:amount, :price, :type, :state) if params[order_type]
    end
  end
end