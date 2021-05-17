class WelcomeController < ApplicationController
  layout 'web'

  def index
    @exchanges = Exchange.all
  end

  def trends
  end
end
