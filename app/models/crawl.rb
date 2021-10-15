class Crawl
	class << self

		def catch_dislocation
			time = 2 + rand(4)
			sleep_time = 60 / time
			time.times.each do |i|
				sleep sleep_time if i > 0
				binance_will_list
			end
		end

		def binance_will_list
			link = "https://www.binance.com/en/support/announcement/c-48"
			doc = Nokogiri::HTML(Faraday.get(link).body)
			announces = doc.css('a.css-1ej4hfo')
			new_announce_info(announces[0])
			if announces.blank?
				Notice.alarm("币安公告页面更新，无法获取列表数据，请及时检查代码逻辑")
			end
		end

		def new_announce_info(announce)
			if announce.content.include? 'Will List'
				title = announce.content
				link = 'https://www.binance.com' + announce.attributes['href'].value
				base = /\((.*)\)/.match(title)[1]
				ann = Announce.create(title: title, link: link)
				gete_market_coin(base) if ann.save
			end
		end

		def gete_market_coin(base)
			symbol = "#{base}_USDT"
			tradable = Gate.first.lists.select {|x| x['id'] == symbol }
			return Notice.tip("Gate 暂不支持 #{base} 相关交易") if tradable.blank?
			market = Gate.first.markets.create(base: base, quote: 'USDT')
			if market.save
				Notice.tip("Gate 新增市场 #{market.symbol}")
				step_bid_order(market) if check_bid_fund(market)
			end
		end

		def check_bid_fund(market)
			exchange = market.exchange
			exchange.sync_account(market)
			balance = exchange.accounts.find_by_asset(market.quote).balance rescue 0
			if balance.zero?
				tip = "#{market.exchange.remark} #{market.exchange.type}账户#{market.quote}余额不足, 无法交易#{market.symbol}, 请检查充值"
				Notice.alarm(tip)
				return false
			end
		end

		def step_bid_order(market)
			continue = true
			exchange = market.exchange
			balance = exchange.accounts.find_by_asset(market.quote).balance rescue 0
			funds = Setting.gate_max_funds
			bid_fund = balance > funds ? funds : balance
			surplus = balance - bid_fund
			while balance >= surplus && continue
				price = market.ticker[:ask].to_f
				amount = (bid_fund / price).to_i
				if amount > 0
					order = market.bids.create(amount: amount, price: price, exchange_id: market.exchange_id)
					result = order.push
					continue = false if result['message']
					exchange.delete_open_order(market) if result['id']
				end
				continue = false if amount.zero?
				exchange.sync_account(market)
				balance = exchange.accounts.find_by_asset(market.quote).balance
				bid_fund = balance - surplus
			end
			base_amount = exchange.accounts.find_by_asset(market.base).balance rescue 0
			Notice.tip("当前购入 #{market.base} 数量： #{base_amount}") if base_amount > 0
		end

	end
end