# == Schema Information
#
# Table name: announces
#
#  id         :integer          not null, primary key
#  link       :string
#  source     :string
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
class Announce < ActiveRecord::Base
  extend Enumerize
  self.per_page = 15
  validates_uniqueness_of :title, scope: :source
  validates_presence_of :title
  scope :recent, -> { order('created_at desc') }
  enumerize :source, in: ['Binance', 'Coinbase', 'Upbit'], default: 'Binance'
  after_create :tip

  def tip
    Notice.tip("[#{source}] " + title)
  end

end
