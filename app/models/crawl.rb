class Crawl
  class << self

    def catch_dislocation
      system("echo '[#{Time.now.long}] Crontab starting ...' >> log/cron_crawl.log")
      time = 2
      sleep_time = 60 / time
      time.times.each do |i|
        sleep sleep_time if i > 0
        binance_will_list
        binance_launchpad_list
      end
    end

    def binance_launchpad_list
      link = "https://www.binance.com/en/support/announcement/c-48"
      html = Nokogiri::HTML(Faraday.get(link).body)
      announces = html.css('a.css-1ej4hfo')
      if announces.blank?
        Notice.alarm("公告列表页面无法解析数据\nhttps://www.binance.com/en/support/announcement/c-48")
      end
      launchpad_trade_toin(announces[0])
      cache_announce(announces[0])
    end

    def binance_will_list
      api_link = 'https://www.binance.com/bapi/composite/v1/public/cms/article/catalog/list/query?pageNo=1&pageSize=5&catalogId=48'
      result = JSON.parse(Faraday.get(api_link).body)
      announce = result['data']['articles'][0] rescue nil
      if announce
        title = announce['title']
        ann = Announce.create(title: title, link: 'json link')
        if ann.save
          system("echo '[#{Time.now.long}] Get new announce #{title}' >> log/cron_crawl.log")
          if title.include? 'Will List'
            base = /\((.*)\)/.match(title)[1]
            gete_market_coin(base)
          end
        end
      end
    end

    def launchpad_trade_toin(announce)
      if announce.content.include? 'Launchpad and Will Open Trading'
        title = announce.content
        link = 'https://www.binance.com' + announce.attributes['href'].value
        base = title.split(' ')[-1]
        time = launchpad_time(link)
        ann = Announce.create(title: title, link: link)
        binance_launchpad(base, time) if ann.save
      end
    end

    def cache_announce(announce)
      title = announce.content + ' for HTML'
      link = 'https://www.binance.com' + announce.attributes['href'].value
      ann = Announce.create(title: title, link: link)
      if ann.save
        system("echo '[#{Time.now.long}] Get new announce #{title}' >> log/cron_crawl.log")
      end
    end

    def launchpad_time(link)
      html = Nokogiri::HTML(Faraday.get(link).body)
      content = html.css('div.css-mm1dbi span.css-1vsinja').map(&:content)
      string = content.select {|l| l.include?('will list') }.join('')
      if string.blank?
        Notice.alarm("公告详情页面无法解析数据\n#{link}")
      end
      time = /(\d{4}-\d{2}-\d{2}\s\d{2}:\d{2})/.match(string).to_s
      time = (time.to_time + 8.hour - 60)&.short
    end

    def binance_launchpad(base, time)
      launchpad = Binance.first.launchpads.create(base: base, quote: 'USDT', launch_at: time, funds: Setting.binance_max_funds)
      Notice.tip("Launchpad New\n Market: #{launchpad.symbol}\n Time: #{time}")
      system("echo '[#{Time.now.long}] Launchpad new market: #{launchpad.symbol}' >> log/cron_crawl.log")
      launchpad.deploy
      system("echo '[#{Time.now.long}] Launchpad deploy: #{launchpad.symbol}' >> log/cron_crawl.log")
    end

    def gete_market_coin(base)
      symbol = "#{base}_USDT"
      tradable = Gate.first.lists.select {|x| x['id'] == symbol }
      return Notice.tip("Gate 不支持 #{base} 相关交易") if tradable.blank?
      market = Gate.first.markets.create(base: base, quote: 'USDT')
      if market.save
        Notice.tip("Gate Market Add #{market.symbol}")
        system("echo '[#{Time.now.long}] Gate market add #{market.symbol}' >> log/cron_crawl.log")
        if market.check_bid_fund?
          funds = Setting.gate_max_funds
          market.step_bid_order(funds)
        end
      end
    end

  end
end
