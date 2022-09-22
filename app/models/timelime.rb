# == Schema Information
#
# Table name: timelimes
#
#  id           :integer          not null, primary key
#  base_vols    :float
#  c_price      :float
#  completed_at :datetime
#  h_price      :float
#  l_price      :float
#  o_price      :float
#  turnover     :float
#  volumes      :float
#  climax_id    :integer
#
class Timelime < ActiveRecord::Base
  validates_uniqueness_of :completed_at, scope: :climax_id
end
