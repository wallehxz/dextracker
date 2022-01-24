# == Schema Information
#
# Table name: trades
#
#  id           :integer          not null, primary key
#  amount       :float
#  cate         :string
#  completed_at :datetime
#  number       :string
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

  def stimestamp
    timestamp.to_i / 1000
  end
end
