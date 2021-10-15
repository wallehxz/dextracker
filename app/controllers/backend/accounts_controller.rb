class Backend::AccountsController < Backend::BaseController
  before_action :find_exchange

  def index
    @accounts = @exchange.accounts.order(balance: :desc).paginate(page:params[:page])
  end

  def edit
  end

  def update
    if @account.update(account_params)
      redirect_to backend_exchange_accounts_path(@exchange), notice: "#{@account.asset}资产标的更新成功"
    else
      flash[:warn] = "请完善表单信息"
      render :edit
    end
  end

private
  def find_exchange
    @exchange = Exchange.find(params[:exchange_id])
  end

  def account_params
    params.require(:account).permit(:quote)
  end

end
