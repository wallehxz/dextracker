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
		crontab = "#{launch_at.strftime('%M %H %d %m *')} /bin/bash -l -c '"
    crontab << "cd #{Rails.root} && bundle exec bin/rails runner -e #{Rails.env} '\\''"
    crontab << "Launchpad.spot_blasting"
    crontab << "'\\'''"
    Open3.capture2("crontab -l > conf && echo \"#{crontab}\" >> conf && crontab conf && rm -f conf")
    self.update(state: 'waiting')
	end

class << self

	def spot_blasting
		Notice.tip("定时打新进程启动....")
		self.waits.each do |launch|
			if Time.now > launch.launch_at
				start_exchange(launch)
				launch.update(state: 'completed')
				Notice.tip("#{launch.symbol} 完成定时打新")
			end
		end
	end

	def start_exchange(launch)
	end

end

end