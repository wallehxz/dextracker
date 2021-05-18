# == Schema Information
#
# Table name: snapshots
#
#  id          :integer          not null, primary key
#  exchange_id :integer
#  estimate    :float
#  period      :string
#  time_stamp  :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
class Snapshot < ActiveRecord::Base
  extend Enumerize
  belongs_to :exchange
  enumerize :period, in: [:day, :hour], default: :day
  scope :days, -> { where(period: 'day') }
  scope :hours, -> { where(period: 'hour') }
  validates_uniqueness_of :time_stamp, scope: [:period, :exchange_id]

  self.per_page = 10

  def market
    self.exchange.type
  end
end
