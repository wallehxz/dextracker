class Backend::AnnouncesController < Backend::BaseController

	def index
    @announces = Announce.paginate(page:params[:page])
  end

  def destroy
    @announce.destroy
    flash[:notice] = "公告信息删除成功"
    redirect_to :back
  end

end