# == Schema Information
#
# Table name: periods
#
#  id         :integer          not null, primary key
#  amount     :float
#  ask_qty    :float
#  bid_qty    :float
#  period     :integer
#  state      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  market_id  :integer
#
class Period < ActiveRecord::Base
  extend Enumerize
  self.per_page = 15
  enumerize :state, in: [:hold, :close], default: :hold
  scope :recent, -> { order('period asc') }
  scope :holds, -> { where(state: :hold) }
  scope :closs, -> { where(state: :close) }
  has_many :trades, primary_key: :market_id, foreign_key: :market_id
  belongs_to :market
  before_create :set_period, :check_blank_period

  def set_period
    self.period = market.periods.size + 1
  end

  def check_blank_period
    false if market.periods.holds.size > 0
  end

  def grand_trades
    bid = 0 ; ask = 0
    complete = false
    precision = market.precision || 2
    pounds    = market.pounds || 0
    h_trades = market.trades.history
    h_trades = h_trades.where(period: [period, nil])
    h_trades.each do |item|
      if bid > pounds && ask > 0
        if bid - ask < "0.#{'0' * precision}1".to_f * 10
          complete = true
          break
        end
      end
      item.update(period: period)
      bid += item.amount if item.cate.bid?
      ask += item.amount if item.cate.ask?
    end if state.hold?
    self.update(amount: ask, state: :close, bid_qty: ptrades.bids.map(&:total).sum, ask_qty: ptrades.asks.map(&:total).sum) if complete
  end

  def ptrades
    trades.where(period: period)
  end

  def start_at
    ptrades.history.first.completed_at
  end

  def finish_at
    ptrades.history.last.completed_at
  end
end
