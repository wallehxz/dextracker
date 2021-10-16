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
	enumerize :state, in: [:initial, :waiting, :completed], default: :initial

	def symbol
		"#{base}-#{quote}"
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
			self.waits.each do |launch|
				if Time.now > launch.launch_at
					start_exchange(launch)
					base_amount = launch.exchange.accounts.find_by_asset(launch.base).balance rescue 0
					if base_amount > 0
						launch.update(state: 'completed')
					end
				end
			end
		end

		def start_exchange(launch)
			market = exchange.markets.find_by(base: launch.base, quote: launch.quote)
			if market.check_bid_fund?
				market.step_bid_order(launch.funds)
			end
		end

	end

end
