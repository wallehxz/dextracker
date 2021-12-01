# == Schema Information
#
# Table name: trades
#
#  id           :integer          not null, primary key
#  amount       :float
#  cate         :string
#  completed_at :datetime
#  number       :integer
#  period       :integer
#  price        :float
#  timestamp    :string
#  total        :float
#  market_id    :integer
#
class Trade < ActiveRecord::Base
  extend Enumerize
  self.per_page = 15
  enumerize :cate, in: [:bid, :ask]
  scope :recent, -> { order('completed_at desc') }
  scope :history, -> { order('completed_at asc') }
  scope :bids, -> { where(cate: 'bid') }
  scope :asks, -> { where(cate: 'ask') }
  belongs_to :market

  def self.check_and_create(market, attributes)
    trade = self.find_or_create_by(market_id: market.id, number: attributes['id'])
    return false if trade.completed_at
    trade.amount = attributes['qty'].to_f
    trade.price = attributes['price'].to_f
    trade.total = attributes['quoteQty'].to_f
    trade.completed_at = Time.at(attributes['time'] / 1000)
    trade.timestamp = attributes['time']
    trade.cate = attributes['isBuyer'] == true ? 'bid' : 'ask'
    trade.save
    true
  end

end
