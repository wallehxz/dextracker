# == Schema Information
#
# Table name: accounts
#
#  id          :integer          not null, primary key
#  asset       :string
#  balance     :float
#  cost        :float
#  freezen     :float
#  quote       :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  exchange_id :integer
#
class Account < ActiveRecord::Base
  self.per_page = 10
  belongs_to :exchange

  after_save :set_quote
  def set_quote
    if quote.blank?
      self.quote = 'USDT'
      save
    end
  end

  def total
    balance + freezen
  end

  def sync_orders
    exchange.all_orders(asset, quote)
  end

  def destroy_empty
    self.destroy! if total.zero?
  end

  def sync_cost
    total = balance + freezen
    bid_cost = exchange.asset_quote_cost(asset, quote, total)
    self.cost = bid_cost
    save
  end

  def self.update_or_create_by(attributes)
    account = self.find_or_create_by(exchange_id: attributes[:exchange_id], asset: attributes[:asset])
    account.update(attributes)
    account.destroy_empty
  end

end
