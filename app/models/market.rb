# == Schema Information
#
# Table name: markets
#
#  id          :integer          not null, primary key
#  base        :string
#  pounds      :float
#  precision   :integer
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
  has_many :trades
  has_many :periods

  def ticker
    exchange.tickers(self)
  end

  def symbol
    exchange.symbol(self)
  end

  def detail
    "#{exchange.type} #{base}-#{quote}"
  end

  def all_trades(start_time = nil, end_time = nil)
    exchange.all_trades(self, start_time, end_time)
  end

  def all_orders(start_time = nil, end_time = nil)
    exchange.all_trades(self, start_time, end_time)
  end

  # 根据参数获取最新和历史数据 period [latest history]
  def cache_trades(period = 'recent')
    continue = true; start_time = nil; end_time = nil
    if trades.size > 0
      start_time = trades.recent.first.timestamp if period == 'recent'
      end_time   = trades.history.first.timestamp if period == 'history'
    end
    while continue
      puts "当前时间范围 start_time [#{start_time}] end_time [#{end_time}]"
      lists = all_orders(start_time, end_time)
      desc_lists = lists.sort { |x,y| y['id'] <=> x['id'] }
      desc_lists.each do |item|
        Trade.check_and_create(self, item)
      end
      continue = false if lists.size < 1000
      if start_time.blank?
        end_time = desc_lists[-1]['time'] if lists.size > 0
      else
        start_time = desc_lists[0]['time'] if lists.size > 0
      end
    end
    if trades.size > 0
      Notice.tip("[#{detail}] 当前同步交易记录 [#{trades.size}] 条")
    end
  end

  def info
    [base, quote]
  end

  def book
    exchange.order_book(self)
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
      time = Time.now.to_i
      exchange.sync_account(self)
      balance = exchange.accounts.find_by_asset(quote)&.balance || 0
      bid_fund = balance > funds ? funds : balance
      surplus = balance - bid_fund
      while balance >= surplus && continue
        continue = false if Time.now.to_i - time > 60
        price = book[:ask]
        next if price.zero?
        amount = (bid_fund / price).to_i
        if amount > 0
          order = bids.create(amount: amount, price: price, exchange_id: exchange_id)
          if result = order.push
            continue = false if result['msg']
            exchange.delete_open_order(self) if result['order']
          end
        end
        continue = false if amount.zero?
        exchange.sync_account(self)
        balance = exchange.accounts.find_by_asset(quote)&.balance || 0
        bid_fund = balance - surplus
      end
      exchange.sync_account(self)
      Notice.tip("当前持有 #{base} 数量： #{exchange.accounts.find_by_asset(base)&.balance.to_f}")
    rescue Exception => detail
      Notice.exception(detail, 'Market step_bid_order')
  end

  def step_limit_bid_order(funds, limit_bid = 0, log_file = nil)
      continue = true
      time = Time.now.to_i
      exchange.sync_account(self)
      balance = exchange.accounts.find_by_asset(quote)&.balance || 0
      bid_fund = balance > funds ? funds : balance
      surplus = balance - bid_fund
      while balance >= surplus && continue
        continue = false if Time.now.to_i - time > 120
        price = book[:ask]
        if price.zero?
          system("echo '[#{Time.now.long}] #{detail} Order Book Is Null' >> #{log_file}") if log_file
          next
        end
        if limit_bid > 0 && price > limit_bid
          system("echo '[#{Time.now.long}] #{detail} Bid price #{price} Over Limit price #{limit_bid}' >> #{log_file}") if log_file
          next
        end
        amount = (bid_fund / price).to_i
        if amount > 0
          order = bids.create(amount: amount, price: price, exchange_id: exchange_id)
          system("echo '[#{Time.now.long}] #{detail} New Order price: #{price} amount: #{amount}' >> #{log_file}") if log_file
          if result = order.push
            if result['msg']
              continue = false
              system("echo '[#{Time.now.long}] #{detail} Order Error #{result['msg']}' >> #{log_file}") if log_file
            end
            exchange.delete_open_order(self) if result['order']
          end
        end
        continue = false if amount.zero?
        exchange.sync_account(self)
        balance = exchange.accounts.find_by_asset(quote)&.balance || 0
        bid_fund = balance - surplus
      end
      exchange.sync_account(self)
      Notice.tip("当前持有 #{base} 数量： #{exchange.accounts.find_by_asset(base)&.balance.to_f}")
    rescue Exception => detail
      Notice.exception(detail, 'Market step_limit_bid_order')
  end

end
