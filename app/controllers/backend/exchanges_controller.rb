class Backend::ExchangesController < Backend::BaseController

  def index
    @exchanges = Exchange.order(:remark).paginate(page:params[:page])
  end

  def new
  end

  def create
    @exchange = Exchange.new(exchange_params)
    if @exchange.save
      redirect_to backend_exchanges_path, notice: '新交易市场添加成功'
    else
      flash[:warn] = "请完善表单信息"
      render :new
    end
  end

  def edit
  end

  def update
    if @exchange.update(exchanges_params)
      redirect_to backend_exchanges_path, notice: '交易平台更新成功'
    else
      flash[:warn] = "请完善表单信息"
      render :edit
    end
  end

  def destroy
    @exchange.destroy
    flash[:notice] = "交易平台删除成功"
    redirect_to :back
  end

  def sync_asset
    @exchange.sync_accounts
    flash[:notice] = "交易所资产同步成功"
    redirect_to :back
  end

  def sync_cost
    @exchange.accounts.map {|a| a.sync_cost }
    flash[:notice] = "交易所资产平均成本同步成功"
    redirect_to :back
  end

private

  def exchange_params
    params.require(:exchange).permit(:app_key, :app_secret, :type, :remark)
  end

  def exchanges_params
    Exchange.exchanges.each do |ex|
      return params.require(ex.to_sym).permit(:app_key, :app_secret, :type, :remark) if params[ex.to_sym]
    end
  end

end
