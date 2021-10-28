class Crawl
  class << self

    def catch_dislocation
      system("echo '[#{Time.now.long}] Crontab starting ...' >> log/cron_crawl.log")
      time = 2
      sleep_time = 60 / time
      time.times.each do |i|
        sleep sleep_time if i > 0
        binance_will_list
        upbit_will_list
        coinbase_will_list
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
    end rescue nil

    def binance_will_list
      api_link = 'https://www.binance.com/bapi/composite/v1/public/cms/article/catalog/list/query?pageNo=1&pageSize=5&catalogId=48'
      result = JSON.parse(Faraday.get(api_link).body)
      announce = result['data']['articles'][0] rescue {}
      title = announce['title']
      if title && title.include?('Will List')
        ann = Announce.create(title: title, link: '#')
        if ann.save
          system("echo '[#{Time.now.long}] Binance Get new announce #{title}' >> log/cron_crawl.log")
          base = /\((.*)\)/.match(title)[1]
          funds = Setting.gate_max_funds
          gete_market_coin(base, funds)
        end
      end
    end rescue nil

    # https://upbit.com/service_center/notice
    def upbit_will_list
      notice_api = 'https://api-manager.upbit.com/api/v1/notices?page=1&per_page=20&thread_name=general'
      result = JSON.parse(Faraday.get(notice_api).body)
      notice = result['data']['list'][0] rescue {}
      unless notice.present?
        return Notice.alarm("Upbit公告接口无效数据\n#{notice_api}")
      end
      title = notice['title'].gsub(' ','')
      if title && title.include?('마켓디지털자산추가')
        title = notice['title']
        ann = Announce.create(title: title, link: '#',source: 'Upbit')
        if ann.save
          system("echo '[#{Time.now.long}] Upbit Get new announce #{title}' >> log/cron_crawl.log")
          coins = title.match(/\((.*)\)/)[1].gsub(' ', '').split(',')
          funds = Setting.upbit_max_funds
          coins.map { |base| gete_market_coin(base, funds) }
        end
      end
    end rescue nil

    # https://blog.coinbase.com/
    def coinbase_will_list
      blog_api = "https://medium.com/_/api/collections/c114225aeaf7/stream?to=#{Time.now.to_i * 1000}&page=2"
      content = Faraday.get(blog_api).body
      result = JSON.parse(/{.*}/.match(content).to_s)
      posts = result['payload']['references']['Post'] rescue {}
      unless posts.present?
        return Notice.alarm("CoinBase公告接口无效数据\n#{blog_api}")
      end
      coins = []
      posts.map {|k, p| coins << p if p['title'].include?('launching on')}
      notice = coins[0]
      title = notice['title']
      ann = Announce.create(title: title, link: '#',source: 'Coinbase')
      if ann.save
        system("echo '[#{Time.now.long}] Coinbase Get new announce #{title}' >> log/cron_crawl.log")
        coins = title.scan(/\(([A-Z]*)\)/).map{|x| x[0]}
        funds = Setting.coinbase_max_funds
        coins.map { |base| gete_market_coin(base, funds) }
      end
    end rescue nil

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

    def gete_market_coin(base, funds = nil)
      return if funds.to_f.zero?
      symbol = "#{base}_USDT"
      tradable = Gate.first.lists.select {|x| x['id'] == symbol }
      return Notice.tip("Gate 不支持 #{symbol} 市场交易") if tradable.blank?
      market = Gate.first.markets.find_or_create_by(base: base, quote: 'USDT')
      if market
        Notice.tip("Gate Market Add #{market.symbol}")
        system("echo '[#{Time.now.long}] Gate market add #{market.symbol}' >> log/cron_crawl.log")
        if market.check_bid_fund?
          market.step_bid_order(funds)
        end
      end
    end rescue nil

  end
end
