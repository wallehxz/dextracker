class Backend::SnapshotsController < Backend::BaseController
  before_action :find_exchange
  def index
    @snapshots = @exchange.snapshots.paginate(page:params[:page])
  end

private
  def find_exchange
    @exchange = Exchange.find(params[:exchange_id])
  end
end
