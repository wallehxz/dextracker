class Backend::BaseController < ApplicationController
  before_action :authenticate_user!, :cookie_sign_in
  load_and_authorize_resource
  layout 'adminlte'

  def current_ability
    @current_ability ||= Ability.new(current_user)
  end
end
