# == Schema Information
#
# Table name: orders
#
#  id          :integer          not null, primary key
#  exchange_id :integer
#  market_id   :integer
#  amount      :float
#  price       :float
#  type        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Order < ActiveRecord::Base
	validates_presence_of :price, :amount, :market_id, :exchange_id
	belongs_to :market
	belongs_to :exchange

	def push
		exchange.sync_order(self)
	end

end
