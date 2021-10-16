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
  self.per_page = 10
	belongs_to :exchange
	validates_uniqueness_of :base, scope: [:exchange_id, :quote]
	has_many :bids, class_name: 'OrderBid'
  has_many :asks, class_name: 'OrderAsk'
  has_many :orders


	def ticker
		exchange.tickers(self)
	end

	def symbol
		exchange.symbol(self)
	end

	def detail
		"#{exchange.type} #{base}-#{quote}"
	end

	def info
		[base, quote]
	end

	def check_bid_fund?
		exchange.sync_account(self)
		balance = exchange.accounts.find_by_asset(quote).balance rescue 0
		if balance.zero?
			tip = "#{exchange.remark} #{exchange.type}账户 #{quote} 余额不足, 无法交易#{symbol}, 请检查充值"
			Notice.alarm(tip)
			return false
		end
		true
	end

	def step_bid_order(funds)
		continue = true
		exchange.sync_account(self)
		balance = exchange.accounts.find_by_asset(quote).balance rescue 0
		bid_fund = balance > funds ? funds : balance
		surplus = balance - bid_fund
		while balance >= surplus && continue
			price = ticker[:ask].to_f
			return Notice.tip("当前无法获取 #{detail} 行情深度，请检查是否开盘交易") if price.zero?
			amount = (bid_fund / price).to_i
			continue = false if amount.zero?
			if amount > 0
				order = bids.create(amount: amount, price: price, exchange_id: exchange_id)
				result = order.push
				continue = false if result['msg']
				exchange.delete_open_order(self) if result['order']
			end
			exchange.sync_account(self)
			balance = exchange.accounts.find_by_asset(quote).balance
			bid_fund = balance - surplus
		end
		base_amount = exchange.accounts.find_by_asset(base).balance rescue 0
		Notice.tip("当前持有 #{base} 数量： #{base_amount}") if base_amount > 0
	end


end
