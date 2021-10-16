# == Schema Information
#
# Table name: orders
#
#  id          :integer          not null, primary key
#  amount      :float
#  price       :float
#  type        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  exchange_id :integer
#  market_id   :integer
#
class OrderBid < Order
end
