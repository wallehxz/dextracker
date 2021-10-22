# == Schema Information
#
# Table name: orders
#
#  id          :integer          not null, primary key
#  amount      :float
#  msg         :string
#  price       :float
#  state       :string
#  type        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  exchange_id :integer
#  market_id   :integer
#

class Order < ActiveRecord::Base
  extend Enumerize
  scope :recent, -> { order('created_at desc') }
  enumerize :state, in: [:initial, :failure, :completed], default: :initial
  validates_presence_of :price, :amount, :market_id, :exchange_id
  belongs_to :market
  belongs_to :exchange

  self.per_page = 10

  def push
    if state.initial?
      result = exchange.sync_order(self)
      update_state(result)
      return result
    end
  end

  def update_state(result)
    if result['order']
      self.update(state: 'completed', msg: '')
    elsif result['msg']
      self.update(state: 'failure', msg: result['msg'])
    end
  end

end
