class Backend::SnapshotsController < Backend::BaseController
  def index
    @snapshots = Snapshot.paginate(page:params[:page])
  end
end
