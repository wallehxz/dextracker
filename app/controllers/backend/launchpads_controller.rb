class Backend::LaunchpadsController < Backend::BaseController

  def index
    @launchpads = Launchpad.paginate(page:params[:page])
  end

  def new
  end

  def create
    @launchpad = Launchpad.new(launchpad_params)
    if @launchpad.save
      redirect_to backend_launchpads_path(@exchange), notice: '定时首发添加成功'
    else
      flash[:warn] = "请完善表单信息"
      render :new
    end
  end

  def edit
  end

  def update
    if @launchpad.update(launchpad_params)
      redirect_to backend_launchpads_path(@exchange), notice: '定时首发更新成功'
    else
      flash[:warn] = "请完善表单信息"
      render :edit
    end
  end

  def destroy
    @launchpad.destroy
    flash[:notice] = "定时首发删除成功"
    redirect_to :back
  end

  def deploy
    market = @launchpad.exchange.markets.find_or_create_by(base: @launchpad.base, quote: @launchpad.quote)
    if market.save && @launchpad.state.initial?
      @launchpad.deploy
      flash[:success] = "部署定时首发成功"
    else
      flash[:warn] = "任务已经部署，请勿重复操作！"
    end
    redirect_to :back
  end

private

  def launchpad_params
    params.require(:launchpad).permit(:exchange_id, :base, :quote, :funds, :state, :launch_at)
  end
end