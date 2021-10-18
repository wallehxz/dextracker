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
class OrderBid < Order
end
