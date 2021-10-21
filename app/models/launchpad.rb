# == Schema Information
#
# Table name: launchpads
#
#  id          :integer          not null, primary key
#  base        :string
#  funds       :float
#  launch_at   :datetime
#  quote       :string
#  state       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  exchange_id :integer
#
require 'open3'
class Launchpad < ActiveRecord::Base
  self.per_page = 10
  extend Enumerize
  belongs_to :exchange
  scope :recent, -> { order('created_at desc') }
  scope :waits, -> { where(state: 'waiting') }
  validates_presence_of :base, :quote, :funds, :launch_at, :exchange_id
  validates_uniqueness_of :base, scope: [:exchange_id, :quote]
  enumerize :state, in: [:initial, :waiting, :completed], default: :initial
  after_create :create_market

  def symbol
    "#{base}-#{quote}"
  end

  def create_market
    exchange.markets.create(base: base, quote: quote)
  end

  def deploy
    if state.initial?
      crontab = "#{launch_at.strftime('%M %H %d %m *')} /bin/bash -l -c '"
      crontab << "cd #{Rails.root} && bundle exec bin/rails runner -e #{Rails.env} '\\''"
      crontab << "Launchpad.spot_blasting"
      crontab << "'\\'''"
      Open3.capture2("crontab -l > conf && echo \"#{crontab}\" >> conf && crontab conf && rm -f conf")
      self.update(state: 'waiting')
    end
  end

  class << self

    def spot_blasting
      Notice.tip("Launchpad Trade Starting at #{Time.now.long}")
      self.waits.each do |launch|
        if Time.now > launch.launch_at
          ex = launch.exchange
          market = ex.markets.find_or_create_by(base: launch.base, quote: launch.quote)

          if market.check_bid_fund?
            market.step_bid_order(launch.funds) rescue nil
          end

          launch.update(state: 'completed')
          Notice.tip("#{market.detail} Launchpad done")
        end
      end
    end

  end
end
