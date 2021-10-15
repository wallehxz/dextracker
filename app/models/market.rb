# == Schema Information
#
# Table name: markets
#
#  id          :integer          not null, primary key
#  base        :string
#  quote       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  exchange_id :integer
#

class Market < ActiveRecord::Base
	belongs_to :exchange
	validates_uniqueness_of :base, scope: [:exchange_id, :quote]
	has_many :bids, class_name: 'OrderBid'
  has_many :asks, class_name: 'OrderAsk'

	def ticker
		exchange.tickers(self)
	end

	def symbol
		exchange.symbol(self)
	end

	def info
		[base, quote]
	end
end
