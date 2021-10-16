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
			if announces.blank?
				Notice.alarm("币安公告页面更新，无法获取列表数据，请及时检查代码逻辑")
			end
			new_announce_info(announces[0])
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
			return Notice.tip("Gate 不支持 #{base} 相关交易") if tradable.blank?
			market = Gate.first.markets.create(base: base, quote: 'USDT')
			if market.save
				Notice.tip("Gate 新增市场 #{market.symbol}")
				if market.check_bid_fund?
					funds = Setting.gate_max_funds
					market.step_bid_order(funds)
				end
			end
		end

	end
end