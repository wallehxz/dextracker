# == Schema Information
#
# Table name: launchpads
#
#  id          :integer          not null, primary key
#  base        :string
#  funds       :float
#  launch_at   :datetime
#  limit_bid   :float            default(0.0)
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
      log_file = 'log/cron_launchpad.log'
      system("echo '[#{Time.now.long}] Launchpad Starting ...' >> #{log_file}") if log_file
      self.waits.each do |launch|
        if Time.now > launch.launch_at
          ex = launch.exchange
          market = ex.markets.find_or_create_by(base: launch.base, quote: launch.quote)

          if market.check_bid_fund?
            system("echo '[#{Time.now.long}] #{market.detail} Trading' >> #{log_file}") if log_file
            market.step_limit_bid_order(launch.funds, launch.limit_bid, log_file)
          end

          launch.update(state: 'completed')
          system("echo '[#{Time.now.long}] #{market.detail} completed' >> #{log_file}") if log_file
        end
      end
    end

  end
end
