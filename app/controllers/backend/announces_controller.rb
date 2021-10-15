class Backend::AnnouncesController < Backend::BaseController

	def index
    @announces = Announce.paginate(page:params[:page])
  end

end