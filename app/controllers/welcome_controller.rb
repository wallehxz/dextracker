class WelcomeController < ApplicationController
  layout 'web'

  def index
    @exchanges = Exchange.all
  end

end
