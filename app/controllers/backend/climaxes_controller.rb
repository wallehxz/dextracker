class Backend::ClimaxesController < Backend::BaseController
  def index
    @climaxes = Climax.paginate(page:params[:page])
  end

  def new
  end

  def create
    @climax = Climax.new(climax_params)
    if @climax.save
      redirect_to backend_climaxes_path(@exchange), notice: '拉盘追涨标的市场添加成功'
    else
      flash[:warn] = "请完善表单信息"
      render :new
    end
  end

  def edit
  end

  def update
    if @climax.update(climax_params)
      redirect_to backend_climaxes_path(@exchange), notice: '拉盘追涨标的市场更新成功'
    else
      flash[:warn] = "请完善表单信息"
      render :edit
    end
  end

  def destroy
    @climax.destroy
    flash[:notice] = "拉盘追涨标的市场删除成功"
    redirect_to :back
  end

  def sync_volumes
    @climax.sync_volumes
    @climax.backtest
    flash[:notice] = "#{@climax.market} 更新成交量"
    redirect_to :back
  end

  def timeline
    @timelimes = @climax.timelimes.order(completed_at: :desc)
  end

private

  def climax_params
    params.require(:climax).permit(:market, :magnife, :volumes)
  end
end